#!/bin/bash

INPUTFILE="$1"
OUTPUTFILE="$2"
if [ -z "$OUTPUTFILE" ]; then
  echo "Usage: $0 <infile> <outfile>" 1>&2
  exit 1
fi

GOP=8
AUDIO_OPTIONS="-acodec libfaac -ac 2"
VIDEO_OPTIONS="-vcodec libx264"
VIDEO_EXTRA="-sc_threshold 0"

#VIDEO_OPTIONS="$VIDEO_OPTIONS -preset veryslow"

FONT="$HOME/Dropbox/Fonts/Envy Code R.ttf"

RATES="
  W=224;H=126;R=5;BV=32;BA=24;AR=22050;P=baseline
  W=400;H=224;R=12.5;BV=128;BA=48;AR=44100;P=baseline
  W=400;H=224;R=25;BV=300;BA=96;AR=44100;P=baseline
  W=640;H=360;R=25;BV=400;BA=96;AR=44100;P=main
  W=640;H=360;R=25;BV=704;BA=96;AR=44100;P=main
  W=688;H=384;R=25;BV=1372;BA=128;AR=48000;P=main
  W=1024;H=576;R=25;BV=2000;BA=96;AR=44100;P=main
  W=1280;H=720;R=25;BV=3372;BA=128;AR=48000;P=high"

#RATES="W=224;H=126;R=5;BV=32;BA=24;AR=22050;P=baseline"

IDX=1
set -x
for RT in $RATES; do
  PFX="$OUTPUTFILE-$IDX"
  FRAG="$PFX/%05d.ts"
  LIST="$PFX.m3u8"

  W=; H=; R=; BV=; BA=; P=; AR=
  eval $RT

  S="${W}x${H}"
  KEYINT=$( perl -e "print $GOP*$R" )

  # Edit the next line with care - the leading and trailing blanks are \xA0 (non-breaking space)
  CAP=" $S ${BV}k "
  FS=$[W/30]
  SH=$[W/400]
  STYLE="fontcolor=white:fontsize=$FS:fontfile=$FONT"
  METRICS="shadowcolor=black@0.7:shadowx=$SH:shadowy=$SH:x=9*W/10-tw:y=8*H/10"
  DT="drawtext=$STYLE:$METRICS:timecode='00\\:00\\:00\\:01':rate=25/1:text='$CAP'" 

  # Due to what looks like an ffmpeg bug specifying audio options screws
  # up the parsing of the -profile option so we process in two stages.

  mkdir -p "$PFX"
  ffmpeg -y -i "$INPUTFILE" -vf "$DT" \
    -map 0:0 -map 0:1 \
    $AUDIO_OPTIONS -ar $AR -b:a ${BA}k \
    $VIDEO_OPTIONS -profile $P $VIDEO_EXTRA \
    -g $KEYINT -keyint_min $[KEYINT/2] -r $R -b:v ${BV}k -s $S \
    -flags -global_header -threads 0 \
    -f segment -segment_time $GOP \
    -segment_list "$LIST" -segment_format mpegts "$FRAG"

  IDX=$[IDX+1]

done
