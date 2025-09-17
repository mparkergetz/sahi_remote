#!/usr/bin/env python3
"""
Concurrent SAHI worker:
  * Uses atomic file locking to pop one .tar directory at a time.
  * Writes one COCO-style JSON per tar inside --out-dir.
  * All logs (info + errors) go to --log-dir/worker_<rank>.log
"""
import argparse, json, logging, os, sys, time, traceback, fcntl
from pathlib import Path

import torch
from sahi.predict import AutoDetectionModel, get_sliced_prediction
from ultralytics import YOLO

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--queue-file", required=True,
                   help="Text file listing absolute paths to tar archives or "
                        "untarred image directories (one per line)")
    p.add_argument("--out-dir", required=True)
    p.add_argument("--log-dir", required=True)
    p.add_argument("--weights", required=True)
    p.add_argument("--slice-size", type=int, default=640)
    p.add_argument("--overlap", type=float, default=0.2)
#    p.add_argument("--batch-size", type=int, default=8)
    return p.parse_args()

class RankFilter(logging.Filter):
    def __init__(self, rank):
        super().__init__()
        self.rank = rank

    def filter(self, record):
        record.rank = self.rank
        return True

def get_logger(rank, log_dir):
    log_dir = Path(log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger(f"GPU{rank}")
    logger.setLevel(logging.INFO)

    formatter = logging.Formatter(
        "%(asctime)s [GPU%(rank)s] %(levelname)s: %(message)s",
        datefmt="%H:%M:%S"
    )

    # File handler
    fh = logging.FileHandler(log_dir / f"worker_{rank}.log")
    fh.setFormatter(formatter)
    fh.addFilter(RankFilter(rank))

    # Stream handler
    sh = logging.StreamHandler(sys.stdout)
    sh.setFormatter(formatter)
    sh.addFilter(RankFilter(rank))

    logger.handlers = [fh, sh]
    logger.propagate = False

    return logger

def images_in(directory: Path):
    return sorted(p for p in directory.rglob("*") if p.suffix.lower() in {".jpg", ".jpeg", ".png"})

def main():
    args = parse_args()
    device = "cuda"
    rank   = int(os.environ.get("LOCAL_RANK", 0))

    log = get_logger(rank, args.log_dir)
    log.info("Worker starting on %s", device)

    model = AutoDetectionModel.from_pretrained(
        model_type="ultralytics",
        model_path='./bombusvaledit_11s_001.pt',
        confidence_threshold=0.3,
        device=f"cuda:{rank}",
    )
    queue_file = Path(args.queue_file)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    failures = []
    while True:
        with queue_file.open("r") as f:
            tar_path = f.readline().strip()
        if not tar_path:
           log.info("Queue was empty – shutting down.")
           return

        tar_path = Path(tar_path)
        # Assume the archive was untarred to SCRATCH/img/<tarname>/...
        img_root = Path(tar_path)
        images = images_in(img_root)
        world_size = int(os.environ.get("WORLD_SIZE", 8))
        #rank = int(os.environ.get("RANK", 0))
        images = images[rank::world_size]
        log.info("Processing %d images from %s", len(images), tar_path.name)

        coco_output = {
            "images": [],
            "annotations": [],
            "categories": [],  # fill if you want
        }
        ann_id = 0
        for img_id, img_fp in enumerate(images):
            try:
                pred = get_sliced_prediction(
                    str(img_fp),
                    model,
                    slice_height=args.slice_size,
                    slice_width=args.slice_size,
                    overlap_height_ratio=args.overlap,
                    overlap_width_ratio=args.overlap,
                    #batch_size=args.batch_size,
                    postprocess_type="NMS",
                    #device=device,
                )
                d = pred.to_coco_dict(img_id=img_id, starting_annotation_id=ann_id)
                coco_output["images"].append(d["images"][0])
                coco_output["annotations"].extend(d["annotations"])
                ann_id += len(d["annotations"])
            except (torch.cuda.OutOfMemoryError, RuntimeError) as e:
                log.error("OOM/RuntimeError on %s: %s", img_fp, e)
                torch.cuda.empty_cache()
                failures.append(str(img_fp))
            except Exception:
                log.error("Exception on %s\n%s", img_fp, traceback.format_exc())
                failures.append(str(img_fp))

        # ---------- write per-tar JSON atomically ----------
        dst_tmp = out_dir / f"{tar_path.stem}.json.tmp"
        dst_final = out_dir / f"{tar_path.stem}.json"
        with dst_tmp.open("w") as f:
            json.dump(coco_output, f)
        dst_tmp.rename(dst_final)

        if failures:
            with (out_dir / "failed_images.txt").open("a") as f:
                f.write("\n".join(failures) + "\n")
            failures.clear()

        log.info("Finished %s  →  %s", tar_path.name, dst_final.name)

    log.info("Worker done.")


if __name__ == "__main__":
    torch.backends.cudnn.benchmark = True  # speed for constant input size
    main()
