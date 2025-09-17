from pathlib import Path
import shutil

# ── Setup paths ─────────────────────────────────────────────────────
results_dir = Path("results")                # Where the .pickle files are
split_dir   = Path("/scratch/getzm/split_dir")             # Where the JPGs still are
done_dir    = Path("/scratch/getzm/DONE")    # Flat destination
done_dir.mkdir(parents=True, exist_ok=True)

# ── 1. Collect base filenames from .pickle files ────────────────────
# Only strip the extension (e.g., image123.pickle → image123)
pickle_bases = {
    p.stem.lower() 
    for p in results_dir.rglob("*.pickle")
}

print(f"Found {len(pickle_bases)} completed base names in {results_dir}")

# ── 2. Walk split_dirs and move any matching .jpg/.jpeg file ────────
moved = 0
for src in split_dir.rglob("*"):
    if src.suffix.lower() not in {".jpg", ".jpeg"}:
        continue

    if src.stem.lower() in pickle_bases:
        dst = done_dir / src.name

        # Avoid overwriting if name already exists
        if dst.exists():
            counter = 1
            while (new_dst := done_dir / f"{src.stem}_{counter}{src.suffix}").exists():
                counter += 1
            dst = new_dst

        shutil.move(src, dst)
        moved += 1
        print(f"Moved: {src}  →  {dst}")

print(f"\nFinished. Moved {moved} image(s) into {done_dir}")
