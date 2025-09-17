import concurrent.futures
from pathlib import Path
import cv2
import shutil

root = Path("/scratch/getzm/raw_imgs/07_26_24")
corrupt_dir = root / "_corrupt"
image_exts = {".jpg", ".jpeg"}

def is_valid(path: Path) -> tuple[Path, bool]:
    try:
        print(f'Checking: {path}')
        img = cv2.imread(str(path))
        return path, img is not None
    except:
        return path, False

files = [p for p in root.rglob("*") if p.suffix.lower() in image_exts and corrupt_dir not in p.parents]

bad = []
with concurrent.futures.ThreadPoolExecutor(max_workers=64) as ex:
    for path, ok in ex.map(is_valid, files):
        if not ok:
            bad.append(path)

if bad:
    print(f"\nFound {len(bad)} corrupt JPEGs:\n")
    for src in bad:
        rel_path = src.relative_to(root)
        dst = corrupt_dir / rel_path
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), dst)
        print(f"Moved: {src} -> {dst}")
else:
    print("All JPEGs loaded without error.")
