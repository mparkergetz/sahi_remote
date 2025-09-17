SRC_TAR_DIR="/home/bpp/getzm/home/bee_cam_datasets/raw_imgs"
CONDA_ENV="/home/$USER/envs/yolo11"
MODEL_WEIGHTS="/home/bpp/getzm/sahi/bombusvaledit_11s_001.pt"

#JOBROOT="/scratch/$USER/${SLURM_JOB_ID}"
SCRATCH="/scratch/getzm"
mkdir -p "$SCRATCH"/{tars,img}

find "$SRC_TAR_DIR" -maxdepth 1 -name '*.tar' -printf "%P\n" | sort > tarlist.txt

echo "Staging $(wc -l < tarlist.txt) .tar archives to $SCRATCH/tars"
rsync -avR --files-from=tarlist.txt "$SRC_TAR_DIR"/ /scratch/getzm/tars/

cd "$SCRATCH/tars"
tar_jobs=$(( SLURM_CPUS_ON_NODE - 8 ))
ls *.tar | parallel -j "$tar_jobs" \
     'tar -I pigz -xf {} -C "$SCRATCH/img/$(basename {} .tar)"'


