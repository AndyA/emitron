#!/bin/bash

source "$( dirname "$0" )/functions.sh"

in="$1"
out="$2"
name="hls3"

singleton "$name"

exec /opt/ffmpeg/bin/ffmpeg -i "$in" \
  -force_key_frames "expr:gte(t,n_forced*8)" \
  -c:v libx264 -vprofile main \
  -s 1280x720 \
  -b:v 2500k \
  -c:a libfaac -ar 44100 -ac 2 -b:a 128k \
  -f flv "$out" < /dev/null 2>> logs/ffmpeg-$name.log

# vim:ts=2:sw=2:sts=2:et:ft=sh

