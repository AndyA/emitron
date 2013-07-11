#!/bin/bash

in="$1"
out="$2"

/opt/ffmpeg/bin/ffmpeg -i "$in" \
  -c copy \
  -f flv "$out" 2>> logs/ffmpeg-hls3.log

# vim:ts=2:sw=2:sts=2:et:ft=sh

