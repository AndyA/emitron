#!/bin/bash

cat <<EOT
#EXTM3U
#EXT-X-MEDIA-SEQUENCE:204
#EXT-X-TARGETDURATION:8
#EXT-X-VERSION:3
EOT

for x in {0..3}{0..9}{0..9}{0..9}; do echo "#EXTINF:8,"; echo mag3/20130712082645-00000$x.ts; done


# vim:ts=2:sw=2:sts=2:et:ft=sh

