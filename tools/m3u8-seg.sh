#!/bin/bash

src=live/hls/test
dst=live/hls/segmenter
cd webroot
srcn=$( basename $src )
dstn=$( basename $dst )

set -x
find $dst -type f -name '*.ts' | xargs rm -f

for br in {1..4}; do
  mkdir -p $dst/$dstn-$br
  m3u8-segmenter -i $src/$srcn-$br.ts \
    -d 8 -p $dst/$dstn-$br/seg \
    -m $dst/$dstn-$br.m3u8 \
    -u http://newstream.fenkle/
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

