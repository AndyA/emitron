#!/bin/bash

iterations=${1:-1}
perl tools/testcard.pl $iterations

sox \
  "|sox -n -p trim 0.0 16.0" \
  "|sox -n -p synth 1.0 sine 1000.0 vol 0.7" \
  "|sox -n -p trim 0.0 3.0" -c 2 -b 16 testcard.tmp.wav

sox_cmd="sox"
while [ $iterations -gt 0 ]; do
  sox_cmd="$sox_cmd testcard.tmp.wav"
  iterations=$[iterations-1]
done
sox_cmd="$sox_cmd testcard.48k.wav"
eval $sox_cmd
sox testcard.48k.wav -r 44100 testcard.wav

keyint=50

set -x
ffmpeg -y -r 25 -i testcard/f%06d.jpeg -i testcard.wav \
  -acodec libfaac -b:a 128k -r:a 44100 \
  -vcodec libx264 -b:v 1000k -r:v 25 \
  -g $keyint -keyint_min $[keyint/2] \
  -threads 0 testcard.ts
set +x

rm -f testcard.wav testcard.48k.wav testcard.tmp.wav

ffmpeg -y -i testcard.ts -absf aac_adtstoasc \
  -acodec copy -vcodec copy testcard.mp4 

# vim:ts=2:sw=2:sts=2:et:ft=sh

