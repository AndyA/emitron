#!/bin/bash

bars=${1-bars.jpg}
duration=${2-60}
out="frames"
rate=25
frames=$[duration * rate]
[ -e "$bars" ] || {
  echo "Can't find $bars" 1>&1
  exit 1
}
echo "Creating $frames frames from $bars"
fn=0
mkdir -p "$out"
while [ $fn -lt $frames ]; do
  outf="$out/$( printf "%08d.jpeg" $fn )"
  ln "$bars" "$outf"
  fn=$[fn+1]
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

