#!/bin/bash

set -x
while true; do
  ./tools/webcam.sh &
  sleep 30
  killall ffmpeg
  sleep 10
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

