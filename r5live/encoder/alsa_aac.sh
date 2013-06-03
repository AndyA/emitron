#!/bin/bash

input="$1"
name=$( echo "$ENC_NAME" | sed -e 's/\./_/' )

set -x

ffmpeg \
  -y -f alsa -i "$input" \
  -ac $# -c:a libfaac -b:a $ENC_BIT_RATE -r:a $ENC_RATE \
  "$ENC_FIFO" < /dev/null > "$ENC_LOG" 2>&1

# vim:ts=2:sw=2:sts=2:et:ft=sh

