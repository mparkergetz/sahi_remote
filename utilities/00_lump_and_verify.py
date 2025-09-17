
import concurrent.futures, os, shutil
from pathlib import Path
from PIL import Image, ImageFile
from datetime import datetime

ImageFile.LOAD_TRUNCATED_IMAGES = False

RAW_ROOT = Path("/scratch/getzm/raw_imgs")
DEST_ROOT = Path("/scratch/getzm/all_imgs")

def is_corrupt_and_copy(path: Path) -> tuple[str, bool, str]:
    try:
        # Try loading the image fully
        with Image.open(path) as im:
            im.load()
    except Exception as e:
        try:
            path.unlink()
        except Exception as del_err:
            return path.name, False, f"delete failed: {del_err}"
        return path.name, False, str(e)

    try:
        # Extract date folder (assumes /raw_imgs/YY_MM_DD/...)
        parts = path.relative_to(RAW_ROOT).parts
        date_folder = parts[0] if len(parts) > 1 else "unknown"
        dest_dir = DEST_ROOT / date_folder
        dest_dir.mkdir(parents=True, exist_ok=True)

        dest_path = dest_dir / path.name
        shutil.move(str(path), dest_path)
        return path.name, True, ""
    except Exception as move_err:
        return path.name, False, f"move failed: {move_err}"

def all_jpgs(root: Path):
    for dirpath, _, filenames in os.walk(root):
        for f in filenames:
            if f.lower().endswith(".jpg"):
                yield Path(dirpath) / f

def main(n_workers=8, chunk_size=100):
    files = list(all_jpgs(RAW_ROOT))
    print(f"Found {len(files):,} image files")

    ok = bad = fail = 0
    with concurrent.futures.ProcessPoolExecutor(max_workers=n_workers) as pool:
        for name, valid, err in pool.map(is_corrupt_and_copy, files, chunksize=chunk_size):
            if valid:
                ok += 1
            else:
                bad += 1
                if "delete failed" in err or "move failed" in err:
                    fail += 1
                print(f"✗ {name} — {err}")

    print(f"\n✓ {ok:,} moved   ✗ {bad:,} deleted or failed   ⚠ {fail:,} delete/move errors")

if __name__ == "__main__":
    main()
