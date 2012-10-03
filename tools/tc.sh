#!/bin/bash

perl tools/testcard.pl

sox \
  "|sox -n -p trim 0.0 16.0" \
  "|sox -n -p synth 1.0 sine 1000.0 vol 0.7" \
  "|sox -n -p trim 0.0 3.0" -c 2 -b 16 testcard.wav

ffmpeg -r 25 -i testcard/f%06d.jpeg -i testcard.wav \
  -acodec libfaac -b:a 256k -r:a 48000 \
  -vcodec libx264 -b:v 1000k -r:v 25 \
  -threads 0 testcard.ts

# vim:ts=2:sw=2:sts=2:et:ft=sh

