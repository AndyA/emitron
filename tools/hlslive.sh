#!/bin/bash

while getopts ':lbpd:' opt; do
  case $opt in
    b) 
      burnin=1 
      ;;
    l) 
      live=1
      ;;
    p)
      preprocess=1
      ;;
    d)
      dog="$OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))

infile="$1"
outdir="$2"
if [ -z "$outdir" ]; then
  echo "Usage: $0 [-l] [-b] [-p] [-d dog.png] <infile> <outdir>" 1>&2
  exit 1
fi

rm -rf "$outdir"
mkdir -p "$outdir"
outfile="$outdir/$( basename "$outdir" )"

work="/tmp/hlslive.$$.work"
mkdir -p "$work"
logs="$work/logs"
mkdir -p "$logs"

gop=8
preset=veryfast
audio_options="-acodec libfaac -ac 2"
video_options="-vcodec libx264"
video_extra="-preset $preset -sc_threshold 0"
pipefmt=mpegts

font="$HOME/Dropbox/Fonts/Envy Code R.ttf"

#rates="
#  W=400;H=224;R=25;BV=300;BA=96;AR=44100;P=baseline
#  W=640;H=360;R=25;BV=704;BA=96;AR=44100;P=main
#  W=688;H=384;R=25;BV=1372;BA=128;AR=48000;P=main
#  W=1024;H=576;R=25;BV=2000;BA=96;AR=44100;P=main"

rates="
  W=400;H=224;R=25;BV=300;BA=96;AR=44100;P=baseline
  W=640;H=360;R=25;BV=704;BA=96;AR=44100;P=baseline
  W=688;H=384;R=25;BV=1372;BA=128;AR=48000;P=baseline
  W=1024;H=576;R=25;BV=2000;BA=96;AR=44100;P=baseline"

fifos=""
tees=""
tokill=""
state=""

function state {
  local ns=$1
  if [ "$ns" != "$state" ]; then
    state=$ns
    echo "### STATE: $state"
  fi
}

function _cleanup() {
  rm -f $fifos
  state 'complete'
}

function _shutdown() {
  kill $tokill
  _cleanup
}

trap _shutdown SIGINT

state 'starting'

source="$infile"
case $infile in
  rtsp://*)
    fifo="$work/input.fifo"
    fifos="$fifos $fifo"
    log="$logs/gst.log"
    mkfifo $fifo
    {
      gst-launch \
        mpegtsmux name=muxer ! filesink location=$fifo \
        rtspsrc location=$infile name=src \
        src. ! rtpmp4gdepay ! queue ! muxer. \
        src. ! rtph264depay ! queue ! muxer. 
    } > "$log" 2>&1 &
    tokill="$! $tokill"
    source="$fifo"
    ;;
  *)
    ;;
esac


# Preprocess
if [ "$preprocess" ]; then
  echo "Starting preprocessor"
  fifo="$work/pre.fifo"
  fifos="$fifos $fifo"
  log="$logs/pre.log"
  extra=""
  if [ "$dog" ]; then
    extra="-i $dog -r:v 25 -filter_complex overlay=120:40"
  fi
  # Make it 16x9
  pad="pad=ih*16/9:ih:(ow-iw)/2:(oh-ih)/2"
  mkfifo $fifo
  {
    ffmpeg -vsync cfr  -y -i "$source" -r:v 25 -r:a 48000 \
      -s 1920x1080 -vf "$pad" $extra \
      -map 0:0 -map 0:1 \
      -acodec pcm_s16le -vcodec rawvideo \
      -f avi "$fifo"
  } > "$log" 2>&1 &
  tokill="$! $tokill"
  source="$fifo"
  pipefmt=avi
fi

tees="cat '$source'"
idx=1
for rt in $rates; do
  pfx="$outfile-$idx"
  frag="$pfx/%08d.ts"

  W=; H=; R=; BV=; BA=; P=; AR=
  eval $rt

  S="${W}x${H}"
  keyint=$( perl -e "print $gop*$R" )

  if [ "$burnin" ]; then
    echo "Burnin enabled"
    # Edit the next line with care - the leading and trailing blanks are
    # \xA0 (non-breaking space)
    cap=" $S ${BV}k "
    fs=72
    sh=2
    style="fontcolor=white:fontsize=$fs:fontfile=$font"
    metrics="shadowcolor=black@0.7:shadowx=$sh:shadowy=$sh:x=9*W/10-tw:y=8*H/10"
    dt="drawtext=$style:$metrics:timecode='00\\:00\\:00\\:01':rate=25/1:text='$cap'" 
  else
    dt="null"
  fi

  echo "Encoding bit rate $idx ($S, ${BV}k)"
  mkdir -p "$pfx"
  fifo="$work/br.$idx.fifo"
  log="$logs/ffmpeg.$idx.log"
  fifos="$fifos $fifo"
  tees="$tees | tee $fifo"
  mkfifo $fifo
  {
    ffmpeg -vsync cfr -f $pipefmt -i "$fifo" \
      -map 0:0 -map 0:1 \
      $audio_options -r:a $AR -b:a ${BA}k \
      $video_options -profile:v $P $video_extra \
      -g $keyint -keyint_min $[keyint/2] -r:v $R -b:v ${BV}k \
      -s $S -vf "$dt" \
      -flags -global_header -threads 0 \
      -f segment -segment_time $gop -segment_format mpegts \
      "$frag" < /dev/null 
    echo
    echo "Exit code: $?"
  } > "$log" 2>&1 &
  idx=$[idx+1]
done

tees="$tees > /dev/null"

eval $tees &
tokill="$! $tokill"

if [ "$live" ]; then
  echo "Starting live HLS packager"
  perl tools/hlswrap.pl --index --gop $gop --live "$outdir" &
  tokill="$! $tokill"
  echo "Running"
  wait
else
  wait
  echo "Packaging HLS on-demand"
  perl tools/hlswrap.pl --index --gop $gop "$outdir"
fi

_cleanup
