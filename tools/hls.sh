#!/bin/bash

in="$1"
out="$2"
if [ -z "$out" ]; then
  echo "sender.sh <infile> <outurl>" 1>&2
  exit 1
fi

frag="$out%05d.ts"
list="$out.m3u8"

fps=25
keyint=200

mkdir -p "$( dirname "$out" )"

set -x
ffmpeg -y -i "$in" \
  -threads 0 \
  -map 0:0 -map 0:1 \
  -acodec libfaac -b:a 96k -r:a 44100 \
  -vcodec libx264 -bf 0 -b:v 400k -r:v $fps -vpre ipod320 \
  -g $keyint -keyint_min $[keyint/2] \
  -flags -global_header -f segment -segment_time $[keyint/fps] \
  -segment_list "$list" -segment_format mpegts \
  -s 720x576 \
  "$frag"

# vim:ts=2:sw=2:sts=2:et:ft=sh

