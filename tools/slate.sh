#!/bin/bash

duration=12
wrk="tmp/slate.$$.tmp"
img="$wrk/img"

mkdir -p "$wrk"

silence="$wrk/silence.wav"
sox -n -r 48000 "$silence" trim 0 $duration

for src in "$*"; do

  name="$( basename "$src" )"
  ext="${name##*.}"
  base="${name%.*}"
  dir="$( dirname "$src" )/$base.slate"
  slate="$dir/slate.ts"
  setmf="$dir/slate.m3u8"
  stmmf="$dir/slate-p1.m3u8"

  mkdir -p "$dir" "$img"
  for fr in sl0{0..9}{0..9}{0..9}; do
    ln "$src" "$wrk/$fr.$ext"
  done

  ffmpeg -y -t $duration -f image2 \
    -i "$wrk/sl%04d.$ext" \
    -i "$silence" \
    -acodec libfaac -b:a 96k \
    -vcodec libx264 -pix_fmt yuv420p -b:v 800k \
    -s 1024x576 -r 25 "$slate"
  rm -rf "$img"

  cat <<EOT > "$setmf"
#EXTM3U
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=96000
slate-p1.m3u8
EOT

  cat <<EOT > "$stmmf"
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:$duration
#EXT-X-ALLOW-CACHE:YES
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-MEDIA-SEQUENCE:1
EOT

  for rep in {1..1000}; do
    cat <<EOT >> "$stmmf"
#EXTINF:$duration,
slate.ts
#EXT-X-DISCONTINUITY
EOT
  done

  cat <<EOT >> "$stmmf"
#EXT-X-ENDLIST
EOT

done
rm -rf "$wrk"

# vim:ts=2:sw=2:sts=2:et:ft=sh

