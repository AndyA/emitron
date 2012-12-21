#!/bin/bash

out="webroot/live/roh-hls-dog"
rm -rf "$out"
mkdir -p "$out"

#for mov in roh/*.mov; do
for mov in roh/dw-titles.mov roh/dw-cam19.mov roh/dw-cam20.mov ; do
  name="$( basename "$mov" )"
  od="$out/${name%.*}"
  echo "$mov -> $od"
  ./tools/hlslive.sh -i -d art/thespace-dog.png "$mov" "$od"
done


# vim:ts=2:sw=2:sts=2:et:ft=sh

