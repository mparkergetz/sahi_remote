#!/bin/bash

for dir in /scratch/getzm/*/; do
    [ -d "$dir" ] || continue

    find "$dir" -mindepth 1 -delete
done

echo "all clean"
