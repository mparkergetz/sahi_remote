#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARLIST="${SCRIPT_DIR}/tarlist.txt"

while IFS= read -r tarfile; do
    if [[ -z "$tarfile" ]]; then
        continue
    fi

    echo "===================================================="
    echo " Processing TAR: $tarfile"
    echo "===================================================="

    # Write a temp tarlist with just the current tar
    echo "$tarfile" > "$TARLIST.single"

    # Override tarlist.txt temporarily with just one tar
    cp "$TARLIST" "$TARLIST.bak"
    mv "$TARLIST.single" "$TARLIST"

    echo ">>> Running 00_untar_to_scratch.sh"
    "${SCRIPT_DIR}/00_untar_to_scratch.sh"

    echo ">>> Running 01_split_dataset.sh"
    "${SCRIPT_DIR}/01_split_dataset.sh"

    echo ">>> Running 02_run_sahi.sh"
    "${SCRIPT_DIR}/02_run_sahi_nostandard.sh"

    echo ">>> Running 03_package_results.sh"
    "${SCRIPT_DIR}/03_package_results.sh"

    echo ">>> Running 04_clean_scratch.sh"
    "${SCRIPT_DIR}/04_clean_scratch.sh"

    echo ">>> Done with $tarfile"
    echo ""

    # Restore original tarlist
    tail -n +2 "$TARLIST.bak" > "$TARLIST"
    rm "$TARLIST.bak"

done < "$TARLIST"

