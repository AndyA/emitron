#!/bin/bash

source="${1:-testcard.mp4}"

while true; do
  ffmpeg -re -i "$source" \
    -acodec libfaac -b:a 128k -r:a 44100 \
    -vcodec libx264 -b:v 2000k -r:v 25 -bf 0 \
    -threads 0 -f flv rtmp://newstream.fenkle/live/phool
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

