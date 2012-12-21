#!/bin/bash

tmp="/tmp/emitron"
work="collect.tmp"
mkdir -p "$work"

find "$tmp" -maxdepth 2 -mindepth 2 -type d | sort -V | while read d; do
  name="$( basename "$d" )"
  out="$work/$name.ts"
  echo "$out"
  cat $( find "$d" -mindepth 1 -maxdepth 1 -type f -name '*.ts' | sort -V ) > "$out"
done
rsync -av $work kumina:~/Desktop

# vim:ts=2:sw=2:sts=2:et:ft=sh

