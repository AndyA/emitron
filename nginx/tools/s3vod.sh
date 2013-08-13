#!/bin/bash

pid="v0001phs"

for x in mag*.m3u8; do
  echo $x
  s3cmd put -P $x s3://thespace-media-live/$pid
done


# vim:ts=2:sw=2:sts=2:et:ft=sh

