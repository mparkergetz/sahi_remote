#!/bin/bash

input_dir="all_imgs"
output_root="split_dirs"
num_splits=8

mkdir -p "$output_root"

# Collect all .jpg files (case-insensitive)
mapfile -t all_files < <(find "$input_dir" -type f \( -iname '*.jpg' \))

# Total number of files
total=${#all_files[@]}
echo "Total files: ${total}"
split_size=$(( (total + num_splits - 1) / num_splits ))

# Split files and move them
for ((i=0; i<num_splits; i++)); do
    out_dir="$output_root/part_$i"
    mkdir -p "$out_dir"
    start=$((i * split_size))
    end=$((start + split_size))
    for ((j=start; j<end && j<total; j++)); do
        cp "${all_files[$j]}" "$out_dir/"
    done
done

echo "Split complete. Images are in $output_root/part_0 to part_7."
