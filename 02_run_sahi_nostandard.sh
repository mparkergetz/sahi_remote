#!/bin/bash

BASE_PARENT="/scratch/getzm/split_dir"
DATE_CODE=$(basename "$(find "$BASE_PARENT" -mindepth 1 -maxdepth 1 -type d | head -n 1)")

BASE_DIR="${BASE_PARENT}/${DATE_CODE}"

if [ ! -d "$BASE_DIR" ]; then
  echo "No valid source directory found in $BASE_PARENT"
  exit 1
fi

echo "Detected source folder: $BASE_DIR"

for i in {0..7}
do
  (
    SOURCE_DIR="${BASE_DIR}/${i}"
    NAME_TAG="${DATE_CODE}_gpu_${i}"

    if [ ! -d "$SOURCE_DIR" ]; then
      echo " Skipping GPU $i: source dir $SOURCE_DIR not found"
      exit 0
    fi

    echo "GPU $i: Running on $SOURCE_DIR → $NAME_TAG"

    CUDA_VISIBLE_DEVICES=$i \
    sahi predict \
      --model_path bombusaddfps_11s_001_640_FRESH_best.pt \
      --model_type ultralytics \
      --source "$SOURCE_DIR" \
      --slice_height 640 \
      --slice_width 640 \
      --overlap_height_ratio 0.2 \
      --overlap_width_ratio 0.2 \
      --project results/ \
      --novisual \
      --no-standard-prediction \
      --export_pickle \
      --name "$NAME_TAG" \
      2> "error_logs/gpu_$i.err" || true
  ) &
done

wait
