from pathlib import Path

root = Path("/scratch/getzm")      # adjust if needed
corrupt_dir = root / "_corrupt"                # where the bad files were moved
split_dir   = root / "split_dirs"              # the directory you want to check against

# ------------------------------------------------------------------
# 1.  Build a set with every *relative* path that exists in split_dirs
#     e.g.   split_dirs/foo/bar.jpg  ->  foo/bar.jpg
# ------------------------------------------------------------------
split_set = {
    p.relative_to(split_dir).as_posix().lower()     # canonical form
    for p in split_dir.rglob("*")
    if p.is_file()
}

# ------------------------------------------------------------------
# 2.  Look at every file in _corrupt and ask:
#     “Does the same relative path exist somewhere in split_dirs?”
# ------------------------------------------------------------------
dupes = []
for bad_file in corrupt_dir.rglob("*"):
    if not bad_file.is_file():
        continue
    rel = bad_file.relative_to(corrupt_dir).as_posix().lower()
    if rel in split_set:
        dupes.append((bad_file, split_dir / rel))

# ------------------------------------------------------------------
# 3.  Report
# ------------------------------------------------------------------
if dupes:
    print(f"Found {len(dupes)} duplicate file(s):\n")
    for bad, good in dupes:
        print(f"  • {bad}   ==   {good}")
else:
    print("No duplicates left in split_dirs/ ✔")
