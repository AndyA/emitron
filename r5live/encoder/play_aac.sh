#!/bin/bash

set -x
ffmpeg -re -y -i "$ENC_SOURCE" -c copy "$ENC_FIFO" < /dev/null > "$ENC_LOG" 2>&1

# vim:ts=2:sw=2:sts=2:et:ft=sh

