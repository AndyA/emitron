#!/bin/bash

in="$1"
out1="$2"
out2="$3"
if [ -z "$out2" ]; then
  echo "sender.sh <infile> <outurl1> <outurl2>" 1>&2
  exit 1
fi

ffmpeg -y -re -i "$in" \
  -acodec copy -vcodec copy \
  -bsf h264_mp4toannexb \
  -f mpegts -threads 0 - < /dev/null | \
    tee >( ffmpeg -y -re -f mpegts -i - \
              -acodec libfaac -b:a 128k -r:a 44100 \
              -vcodec libx264 -bf 0 -b:v 400k -r:v 25 \
              -s 720x576 -f mpegts -threads 0 "$out1" ) | \
    tee >( ffmpeg -y -re -f mpegts -i - \
              -acodec libfaac -b:a 128k -r:a 44100 \
              -vcodec libx264 -bf 0 -b:v 1200k -r:v 25 \
              -s 1280x720 -f mpegts -threads 0 "$out2" ) > /dev/null

# vim:ts=2:sw=2:sts=2:et:ft=sh

