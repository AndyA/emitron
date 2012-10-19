#!/bin/bash

#      -bsf:a aac_adtstoasc

remote=newstream.fenkle
me=$( hostname -s )
url=rtmp://$remote/live/$me
rate=15

function wc_default() {
  v4l2-ctl -p $rate
  ffmpeg -y \
    -f alsa -ac 1 -r:a 48000 -i hw:1,0 \
    -f video4linux2 -r:v $rate -i /dev/video0 \
    -vf 'format=yuv420p' \
    -acodec libfaac -b:a 128k -ac 2 \
    -vcodec libx264 -b:v 2000k \
    -profile:v baseline -bf 0 -g 100 -keyint_min 50 -r:v 15 \
    -threads 0 -f flv "$url"
}

function wc_orac() {
  rate=30
  v4l2-ctl --set-fmt-video=width=1920,height=1080,pixelformat=1
  v4l2-ctl --set-parm=30
  ffmpeg -y \
    -f alsa -ac 2 -r:a 48000 -i hw:1,0 \
    -f h264 -i <( tools/capture -o ) \
    -acodec libfaac -b:a 128k -ac 2 \
    -vcodec copy \
    -threads 0 -f flv "$url"
}

set -x
case $me in
  orac)
    wc_orac
    ;;
  *)
    wc_default
    ;; 
esac


# vim:ts=2:sw=2:sts=2:et:ft=sh
