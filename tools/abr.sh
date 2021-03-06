#!/bin/bash

INPUTFILE="$1"
OUTPUTDIR="$2"
if [ -z "$OUTPUTDIR" ]; then
  echo "Usage: $0 <infile> <outdir>" 1>&2
  exit 1
fi

OUTPUTFILE="$OUTPUTDIR/$( basename "$OUTPUTDIR" )"

GOP=8
[ -z "$BURNIN" ] && BURNIN=true
AUDIO_OPTIONS="-acodec libfaac -ac 2"
VIDEO_OPTIONS="-vcodec libx264"

FONT="$HOME/Dropbox/Fonts/Envy Code R.ttf"

RATES="
  W=400;H=224;R=25;BV=300;BA=96;AR=44100;P=baseline
  W=640;H=360;R=25;BV=704;BA=128;AR=44100;P=main
  W=1024;H=576;R=25;BV=1500;BA=128;AR=44100;P=main
  W=1280;H=720;R=25;BV=2200;BA=192;AR=44100;P=main"

FIFOS=""
TEES=""

function _shutdown() {
  rm -f $FIFOS
}

trap _shutdown SIGINT

TEES="ffmpeg -y -i '$INPUTFILE' -acodec copy -vcodec copy -f mpegts - < /dev/null"

IDX=1
set -x
for RT in $RATES; do
  PFX="$OUTPUTFILE-$IDX"
  FRAG="$PFX/%05d.ts"
  M3U8="$PFX/m.m3u8"

  W=; H=; R=; BV=; BA=; P=; AR=
  eval $RT

  S="${W}x${H}"

  if $BURNIN; then
    # Edit the next line with care - the leading and trailing blanks are \xA0 (non-breaking space)
    CAP=" $S ${BV}k "
    FS=$[W/30]
    SH=$[W/400]
    STYLE="fontcolor=white:fontsize=$FS:fontfile=$FONT"
    METRICS="shadowcolor=black@0.7:shadowx=$SH:shadowy=$SH:x=9*W/10-tw:y=8*H/10"
    DT="drawtext=$STYLE:$METRICS:timecode='00\\:00\\:00\\:01':rate=25/1:text='$CAP'" 
  else
    DT="null"
  fi

  mkdir -p "$( dirname "$FRAG" )"
  FIFO="/tmp/hlslive.$$.$IDX.fifo"
  FIFOS="$FIFOS $FIFO"
  TEES="$TEES | tee $FIFO"
  mkfifo $FIFO
  ffmpeg -y -f mpegts -i "$FIFO" -vf "$DT" \
    -map 0:0 -map 0:1 \
    $AUDIO_OPTIONS -ar $AR -b:a ${BA}k \
    $VIDEO_OPTIONS -profile $P \
    -force_key_frames "expr:gte(t,n_forced*$GOP)" \
    -r $R -b:v ${BV}k -s $S \
    -flags -global_header -threads 0 \
    -f segment \
    -segment_time $GOP \
    -segment_format mpegts \
    -segment_list "$M3U8" \
    -segment_list_type m3u8 \
    "$FRAG" < /dev/null &

  IDX=$[IDX+1]

done

TEES="$TEES > /dev/null"
eval $TEES &

wait
_shutdown
