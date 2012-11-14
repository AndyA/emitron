#!/bin/bash

while getopts 'lb' opt; do
  case $opt in
    b) 
      BURNIN=1 
      ;;
    l) 
      LIVE=1
      ;;
  esac
done
shift $((OPTIND-1))

INPUTFILE="$1"
OUTPUTDIR="$2"
if [ -z "$OUTPUTDIR" ]; then
  echo "Usage: $0 [-l] [-b] <infile> <outdir>" 1>&2
  exit 1
fi

OUTPUTFILE="$OUTPUTDIR/$( basename "$OUTPUTDIR" )"

GOP=8
PRESET=veryfast
AUDIO_OPTIONS="-acodec libfaac -ac 2"
VIDEO_OPTIONS="-vcodec libx264"
VIDEO_EXTRA="-preset $PRESET -sc_threshold 0"

FONT="$HOME/Dropbox/Fonts/Envy Code R.ttf"

#RATES="
#  W=400;H=224;R=25;BV=300;BA=96;AR=44100;P=baseline
#  W=640;H=360;R=25;BV=704;BA=96;AR=44100;P=main
#  W=688;H=384;R=25;BV=1372;BA=128;AR=48000;P=main
#  W=1024;H=576;R=25;BV=2000;BA=96;AR=44100;P=main"

RATES="
  W=400;H=224;R=25;BV=300;BA=96;AR=44100;P=baseline
  W=640;H=360;R=25;BV=704;BA=96;AR=44100;P=baseline
  W=688;H=384;R=25;BV=1372;BA=128;AR=48000;P=baseline
  W=1024;H=576;R=25;BV=2000;BA=96;AR=44100;P=baseline"

FIFOS=""
TEES=""
TOKILL=""

function _cleanup() {
  rm -f $FIFOS
}

function _shutdown() {
  kill $TOKILL
  _cleanup
}

trap _shutdown SIGINT

#TEES="cvlc --rtsp-tcp '$INPUTFILE' --sout file/ts://-"
#TEES="ffmpeg -y -i '$INPUTFILE' -acodec copy -vcodec copy -bsf:v h264_mp4toannexb -f mpegts - < /dev/null"
TEES="cat '$INPUTFILE'"
#TEES="buffer -i '$INPUTFILE'"

IDX=1
set -x
for RT in $RATES; do
  PFX="$OUTPUTFILE-$IDX"
  FRAG="$PFX/%05d.ts"

  W=; H=; R=; BV=; BA=; P=; AR=
  eval $RT

  S="${W}x${H}"
  KEYINT=$( perl -e "print $GOP*$R" )

  if [ "$BURNIN" ]; then
    # Edit the next line with care - the leading and trailing blanks are \xA0 (non-breaking space)
    CAP=" $S ${BV}k "
    FS=72
    SH=2
    STYLE="fontcolor=white:fontsize=$FS:fontfile=$FONT"
    METRICS="shadowcolor=black@0.7:shadowx=$SH:shadowy=$SH:x=9*W/10-tw:y=8*H/10"
    DT="drawtext=$STYLE:$METRICS:timecode='00\\:00\\:00\\:01':rate=25/1:text='$CAP'" 
  else
    DT="null"
  fi

  # Make it 16x9
  PAD="pad=ih*16/9:ih:(ow-iw)/2:(oh-ih)/2"

  mkdir -p "$PFX"
  FIFO="/tmp/hlslive.$$.$IDX.fifo"
  FIFOS="$FIFOS $FIFO"
  TEES="$TEES | tee $FIFO"
  mkfifo $FIFO
  ffmpeg -vsync cfr -f mpegts -i "$FIFO" \
    -map 0:0 -map 0:1 \
    $AUDIO_OPTIONS -r:a $AR -b:a ${BA}k \
    $VIDEO_OPTIONS -profile:v $P $VIDEO_EXTRA \
    -g $KEYINT -keyint_min $[KEYINT/2] -r:v $R -b:v ${BV}k \
    -s $S -vf "$PAD,$DT" \
    -flags -global_header -threads 0 \
    -f segment -segment_time $GOP -segment_format mpegts \
    "$FRAG" < /dev/null &
  IDX=$[IDX+1]
done

TEES="$TEES > /dev/null"

eval $TEES &
TOKILL="$! $TOKILL"

if [ "$LIVE" ]; then
  perl tools/hlswrap.pl --index --gop $GOP --live "$OUTPUTDIR" &
  TOKILL="$! $TOKILL"
  wait
else
  wait
  echo "Generating m3u8s"
  perl tools/hlswrap.pl --index --gop $GOP "$OUTPUTDIR"
fi

_cleanup
