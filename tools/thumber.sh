#!/bin/bash

function die {
  echo "Fatal: $@" 1>&2
  exit 1
}

width=160
height=90

for dir in "$@"; do
  find "$dir" -type f -name '*.ts' | sort -V | while read ts; do
    thumb="${ts%.ts}.jpeg"
    echo "$ts -> $thumb"
    ffmpeg -y -i "$ts" -r 1 -vframes 1 -s "${width}x${height}" -f image2 "$thumb" < /dev/null
  done
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

