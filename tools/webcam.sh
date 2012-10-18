#!/bin/bash


ffmpeg -y \
  -f alsa -ac 1 -r:a 48000 -i hw:1,0 \
  -f video4linux2 -i /dev/video0 \
  -vf 'format=yuv420p' \
  -acodec libfaac -b:a 128k -ac 2 \
  -vcodec libx264 -b:v 2000k -r:v 25 \
  -profile:v baseline -bf 0 -g 100 -keyint_min 50 \
  -threads 0 -f flv rtmp://localhost/live/phool



# vim:ts=2:sw=2:sts=2:et:ft=sh
