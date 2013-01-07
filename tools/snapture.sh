#!/bin/bash

function die {
  echo "Fatal: $@" 1>&2
  exit 1
}

stream="$1"
[ "$stream" ] || die "Please name an rtmp stream (rtmp://hostname/app/stream)"
capf="$( basename "$stream" )"
seq=0

while true; do
  capfn="$( printf "%s-%04d.flv" $capf $seq )"
  seq=$[seq+1]
  echo "$stream -> $capfn"
  rtmpdump -v -o "$capfn" -r "$stream" 
  sleep 5
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

