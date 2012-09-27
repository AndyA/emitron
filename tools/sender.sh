#!/bin/bash

in="$1"
out="$2"
if [ -z "$out" ]; then
  echo "sender.sh <infile> <outurl>" 1>&2
  exit 1
fi

set -x
ffmpeg -y -re -i "$in" \
  -acodec libfaac -b:a 32k -r:a 44100 \
  -vcodec libx264 -bf 0 -b:v 64k -r:v 12 \
  -f mpegts -threads 0 \
  "$out"

# vim:ts=2:sw=2:sts=2:et:ft=sh

