#!/bin/bash

while sleep 60; do
  keep=$( date +%H%M%S )
  out="tmp/keep/$keep"
  mkdir -p "$out"
  echo "$out"
  find tmp/s3/mag -name '*.m3u8' | while read m3u8; do
    cp "$m3u8" "$out"
  done
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

