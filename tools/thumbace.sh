#!/bin/bash

tmp="tmp"
log="$tmp/frames.$$.log"
out="webroot/ace"

mkdir -p "$out"
for mpg in ~/ACE/raw/*.mpg; do
  name="$( basename "$mpg" ".mpg" )"
  outd="$out/$name"
  frames="$outd/frames"
  if [ ! -d "$frames" ]; then
    echo "$mpg $frames"
    tmpf="$tmp/frames.$name.tmp"
    rm -rf "$tmpf"
    mkdir -p "$tmpf"
    ffmpeg -y -i "$mpg" -r 1 -f image2 "$tmpf/%08d.jpeg" < /dev/null >> "$log" 2>&1
    mv "$tmpf" "$frames"
  fi
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

