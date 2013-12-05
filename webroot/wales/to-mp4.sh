#!/bin/bash

out="mp4"

set -x
mkdir -p "$out"

find a b -name '*.m3u8' | while read mf; do
  echo "$mf"
  mn="$( basename "$mf" .m3u8 )"
  [ "$mn" = "a" ] && mn="$( basename "$( dirname "$mf" )" )"
  outf="$PWD/$out/$mn.mp4"
  echo "$mn $outf"
  pushd "$( dirname "$mf" )"
  ffmpeg -y -i "$( basename "$mf" )" \
    -af aresample=osr=44100:filter_size=256:cutoff=1 \
    -movflags faststart \
    -c:v copy -c:a libfaac -b:a 128k "$outf" < /dev/null
  popd
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

