#!/bin/bash

name=$( echo "$ENC_NAME" | sed -e 's/\./_/' )

set -x

ffmpeg \
  -y -f jack -i "$name" \
  -ac $# -c:a libfaac -b:a $ENC_BIT_RATE -r:a $ENC_RATE \
  "$ENC_FIFO" < /dev/null > "$ENC_LOG" 2>&1 &

sleep 2

next=1
for inp in "$@"; do
  chan="$name:input_$next"
  jack_connect "$inp" "$chan"
  next=$[next+1]
done

wait

# vim:ts=2:sw=2:sts=2:et:ft=sh

