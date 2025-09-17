#!/usr/bin/env bash
# Stage all .tar archives to node-local scratch *and* launch the GPU job

SRC_TAR_DIR="/home/bpp/getzm/home/bee_cam_datasets/raw_imgs"
SBATCH_PARTITION="cqls_gpu-1080"
CONDA_ENV="/home/$USER/envs/yolo11"
MODEL_WEIGHTS="/home/bpp/getzm/sahi/bombusvaledit_11s_001.pt"

set -euo pipefail
JOBROOT="/scratch/getzm/$(date +%F_%H%M)"
SCRATCH="$JOBROOT/data"

find "$SRC_TAR_DIR" -maxdepth 1 -name '*.tar' -print0 | sort -z | xargs -0 -I{} realpath "{}" > tarlist.txt

sbatch --job-name=sahi_infer \
       --partition="$SBATCH_PARTITION" \
       --nodes=1 \
       --ntasks=8 \
       --gpus-per-task=1 \
       --cpus-per-task=4 \
       --export=ALL,SCRATCH="$SCRATCH",CONDA_ENV="$CONDA_ENV",MODEL_WEIGHTS="$MODEL_WEIGHTS" \
       01_run_sahi.sbatch tarlist.txt

echo "Submitted SAHI job; logs will appear in slurm-<jobid>.out"
