#!/bin/bash


ffmpeg -y \
  -f alsa -ac 1 -r:a 48000 -i hw:1,0 \
  -f video4linux2 -i /dev/video0 \
  -acodec libfaac -b:a 128k \
  -vcodec libx264 -b:v 2000k -r:v 25 -bf 0 \
  -threads 0 -f flv rtmp://newstream.fenkle/live/phool

# vim:ts=2:sw=2:sts=2:et:ft=sh
