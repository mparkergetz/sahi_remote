#!/bin/bash
set -euo pipefail

EMAIL="getzm@oregonstate.edu"
SCRIPT_NAME="run_all.sh"
LOGFILE="/scratch/getzm/${SCRIPT_NAME%.sh}_$(date +%Y%m%d_%H%M%S).log"

# Log everything to file and also show in terminal
exec > >(tee "$LOGFILE") 2>&1

# Error handler: runs on any error
error_handler() {
    local exit_code=$?
    echo "[$SCRIPT_NAME] failed with exit code $exit_code. See log: $LOGFILE"

    (
        echo "To: $EMAIL"
        echo "Subject: $SCRIPT_NAME FAILED on $(hostname)"
        echo "Content-Type: text/plain"
        echo
        echo "The script $SCRIPT_NAME failed at: $(date)"
        echo "Host: $(hostname)"
        echo "Exit code: $exit_code"
        echo
        echo "---- Begin Log Output ----"
        tail -n 100 "$LOGFILE"
        echo "---- End Log Output ----"
    ) | /usr/sbin/sendmail -t

    exit $exit_code
}

trap error_handler ERR

# ========== Your Existing Logic Below ==========

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARLIST="${SCRIPT_DIR}/tarlist.txt"

while IFS= read -r tarfile; do
    [[ -z "$tarfile" ]] && continue

    echo "===================================================="
    echo " Processing TAR: $tarfile"
    echo "===================================================="

    echo "$tarfile" > "$TARLIST.single"

    cp "$TARLIST" "$TARLIST.bak"
    mv "$TARLIST.single" "$TARLIST"

    echo ">>> Running 00_untar_to_scratch.sh"
    "${SCRIPT_DIR}/00_untar_to_scratch.sh"

    echo ">>> Running 01_split_dataset.sh"
    "${SCRIPT_DIR}/01_split_dataset.sh"

    echo ">>> Running 02_run_sahi.sh"
    "${SCRIPT_DIR}/02_run_sahi.sh"

    echo ">>> Running 03_package_results.sh"
    "${SCRIPT_DIR}/03_package_results.sh"

    echo ">>> Running 04_clean_scratch.sh"
    "${SCRIPT_DIR}/04_clean_scratch.sh"

    echo ">>> Done with $tarfile"
    echo ""

    tail -n +2 "$TARLIST.bak" > "$TARLIST"
    rm "$TARLIST.bak"

done < "$TARLIST"

echo "All tars processed successfully at $(date)"
