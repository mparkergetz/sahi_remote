#!/bin/bash

set -euo pipefail

TARLIST="tarlist.txt"
TAR_DIR="/home/bpp/getzm/home/bee_cam_datasets/raw_imgs/tars"
SCRATCH_DIR="/scratch/getzm/all_imgs"

if ! read -r FIRST_FILE < "$TARLIST"; then
    echo "tarlist.txt is empty or unreadable."
    exit 1
fi

FULL_PATH="${TAR_DIR}/${FIRST_FILE}"

if [[ ! -f "$FULL_PATH" ]]; then
    echo "File not found: $FULL_PATH"
    exit 1
fi

echo "Untarring $FIRST_FILE to $SCRATCH_DIR"
if tar -xf "$FULL_PATH" -C "$SCRATCH_DIR"; then
    echo "Successfully extracted: $FIRST_FILE"

    tail -n +2 "$TARLIST" > "${TARLIST}.tmp" && mv "${TARLIST}.tmp" "$TARLIST"
else
    echo "Failed to extract: $FIRST_FILE"
    exit 1
fi
