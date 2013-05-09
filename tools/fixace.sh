#!/bin/bash

gop=8
root="webroot/ace"
find "$root" -name 'index.html' | while read idx; do
  dir="$( dirname "$idx" )"
  echo "$dir"
  perl tools/hlswrap.pl --index --gop $gop "$dir"
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

