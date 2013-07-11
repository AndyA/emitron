#!/bin/bash

in="$1"
out="$2"

/opt/ffmpeg/bin/ffmpeg -i "$in" \
  -force_key_frames "expr:gte(t,n_forced*8)" \
  -c:v libx264 -vprofile main \
  -s 400x224 \
  -b:v 350k \
  -c:a libfaac -ar 44100 -ac 2 -b:a 96k \
  -f flv "$out" 2>> logs/ffmpeg-hls1.log

# vim:ts=2:sw=2:sts=2:et:ft=sh

