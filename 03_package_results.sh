set -euo pipefail

cd results

DATE_PREFIX=$(
  find . -maxdepth 1 -type d -regextype posix-extended -regex './[0-9]{2}_[0-9]{2}_[0-9]{2}_gpu_[0-9]+' \
  -printf '%f\n' \
  | sed 's,_gpu_[0-9]\+$,,g' \
  | sort | tail -n 1
)
echo "date prefix: $DATE_PREFIX"

TARGET_DIR="../${DATE_PREFIX}_results"
mkdir -p "$TARGET_DIR"

echo "rsyncing pickle files from all ${DATE_PREFIX}_gpu_* subdirs to $TARGET_DIR"
for SRC_DIR in ${DATE_PREFIX}_gpu_*; do
    if [[ -d "$SRC_DIR" ]]; then
        echo "  processing $SRC_DIR"
        rsync -a --info=progress2 --prune-empty-dirs \
          --include='*/' --include='*.pickle' --exclude='*' \
          "$SRC_DIR"/ "$TARGET_DIR"/
    fi
done

echo "deleting copied source pickle files"
for SRC_DIR in ${DATE_PREFIX}_gpu_*; do
    if [[ -d "$SRC_DIR" ]]; then
        find "$SRC_DIR" -type f -name '*.pickle' -delete
        find "$SRC_DIR" -type d -empty -delete
    fi
done

echo "tarring (uncompressed)"
cd ..
tar -cf "${DATE_PREFIX}_results.tar" "${DATE_PREFIX}_results"

echo "copying tar to bee_cam_results"
rsync -a "${DATE_PREFIX}_results.tar" /home/bpp/getzm/home/bee_cam_results || {
    echo "rsync failed, exiting"
    exit 1
}

echo "cleaning up"
rm -rf "${DATE_PREFIX}_results"
echo "done"
