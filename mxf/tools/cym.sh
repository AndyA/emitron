#!/bin/bash

#in="wales/WG0001323_PEET034K.mxf"
bars="bars-mpeg.mov"
in="foo.mov"
out="part-out.mov"

ffmpeg -y -i "$in" \
  -vf format=yuv420p,yadif,crop=720:576:0:32 \
  -c:a libfaac -b:a 192k \
  -c:v libx264 -b:v 5000k \
  -aspect 16:9 \
  "$out"

exit

  -pix_fmt yuv420p \
  -vf format=yuv420p,yadif,crop=720:576:0:32 \

# vim:ts=2:sw=2:sts=2:et:ft=sh

