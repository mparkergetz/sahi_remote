#!/bin/bash
#SBATCH --output=%j.out

#SCRATCH="/scratch/getzm"

#cat tarlist.txt | sed 's/\.tar$//' | while read base; do
#    echo "$SCRATCH/img/$base"
#done > queue.txt

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate yolo11

srun --label python3 -u "/home/bpp/getzm/sahi/detect_worker.py" \
     --queue-file "queue.txt" \
     --out-dir    "/home/bpp/getzm/sahi/json" \
     --log-dir    "/home/bpp/getzm/sahi/log" \
     --weights    "/home/bpp/getzm/sahi/bombusvaledit_11s_001.pt"
