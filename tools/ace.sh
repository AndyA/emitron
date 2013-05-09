#!/bin/bash

out="webroot/ace"
mkdir -p "$out"
for f in ~/ACE/raw/*.mpg; do
  name="$( basename "$f" ".mpg" )"
  outd="$out/$name"
  echo "$f $outd"
  if [ -d "$outd" ]; then
    echo "$outd exists, skipping"
  else
    echo "Encoding $f to $outd"
    ./tools/hlslive.sh -p "$f" "$outd"
  fi
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

