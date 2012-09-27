#!/bin/bash

INPUTFILE="$1"
OUTPUTDIR="$2"
if [ -z "$OUTPUTDIR" ]; then
  echo "Usage: $0 <infile> <outfile>" 1>&2
  exit 1
fi

OUTPUTFILE="$OUTPUTDIR/$( basename "$OUTPUTDIR" )"

GOP=8
PRESET=veryfast
AUDIO_OPTIONS="-acodec libfaac -ac 2"
VIDEO_OPTIONS="-vcodec libx264"
VIDEO_EXTRA="-preset $PRESET -sc_threshold 0"

FONT="$HOME/Dropbox/Fonts/Envy Code R.ttf"

RATES="
  W=400;H=224;R=12.5;BV=128;BA=48;AR=44100;P=baseline
  W=640;H=360;R=25;BV=400;BA=96;AR=44100;P=main
  W=688;H=384;R=25;BV=1372;BA=128;AR=48000;P=main
  W=1280;H=720;R=25;BV=3372;BA=128;AR=48000;P=high"

#RATES="W=224;H=126;R=5;BV=32;BA=24;AR=22050;P=baseline"

FIFOS=""
TEES=""

function _shutdown() {
  rm -f $FIFOS
}

trap _shutdown SIGINT

TEES="ffmpeg -re -y -i '$INPUTFILE' -acodec copy -vcodec copy -f mpegts - < /dev/null"

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

  mkdir -p "$PFX"
  FIFO="/tmp/hlslive.$$.$IDX.fifo"
  FIFOS="$FIFOS $FIFO"
  TEES="$TEES | tee $FIFO"
  mkfifo $FIFO
  ffmpeg -re -y -f mpegts -i "$FIFO" -vf "$DT" \
    -map 0:0 -map 0:1 \
    $AUDIO_OPTIONS -ar $AR -b:a ${BA}k \
    $VIDEO_OPTIONS -profile $P $VIDEO_EXTRA \
    -g $KEYINT -keyint_min $[KEYINT/2] -r $R -b:v ${BV}k -s $S \
    -flags -global_header -threads 0 \
    -f segment -segment_time $GOP -segment_format mpegts \
    "$FRAG" < /dev/null &

  IDX=$[IDX+1]

done

TEES="$TEES > /dev/null"
eval $TEES &

wait
_shutdown
