#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

SRC_ROOT="/scratch/getzm/all_imgs"
DST_ROOT="/scratch/getzm/split_dir"

for subdir in "$SRC_ROOT"/*/; do
    [ -d "$subdir" ] || continue
    base=${subdir%/}
    base="$(basename "$base")"

    if [[ $base =~ ^([0-1][0-9]_[0-3][0-9]_[0-9]{2})(_|$) ]]; then
        date_tag="${BASH_REMATCH[1]}"
    else
        date_tag="$base"
        echo "No date found in '$base', using folder name as tag: $date_tag" >&2
    fi

    echo "Processing $base -> $date_tag ..."

    for i in {0..7}; do
        mkdir -p "$DST_ROOT/$date_tag/$i"
    done

    find "$subdir" -type f -iname '*.jpg' -print0 \
    | shuf -z \
    | parallel -0 --no-run-if-empty --jobs 32 --line-buffer '
        n={#}
        d=$(( (n - 1) % 8 ))
        mv -- "{}" "'"$DST_ROOT"'/'"$date_tag"'/$d/"
    '
done

