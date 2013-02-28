#!/bin/bash

tmp="tmp"
root="webroot/ace"
tmpf="$tmp/thumbs.$$.jpeg"
log="$tmp/thumbs.$$.log"
mkdir -p "$tmp"

find "$root" -type d -name '*-p70' | sort -V | while read dir; do
  parent="$( dirname "$dir" )"
  name="$( basename "$parent" )"
  thumbs="$parent/thumbs"
  mkdir -p "$thumbs"
  find "$dir" -type f -name '*.ts' | sort -V | while read ts; do
    thumb="$thumbs/$( basename "${ts%.ts}.jpeg" )"
    if [ ! -e "$thumb" ]; then
      echo "$ts -> $thumb"
      ffmpeg -y -i "$ts" \
        -r 1 -vframes 1 \
        -f image2 "$tmpf" < /dev/null >> "$log" 2>& 1 && mv "$tmpf" "$thumb"
    fi
  done
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

