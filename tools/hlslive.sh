#!/bin/bash

while getopts ':lbipd:' opt; do
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
    i)
      deinterlace=1
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
#  W=640;H=360;R=25;BV=704;BA=96;AR=44100;P=baseline
#  W=688;H=384;R=25;BV=1372;BA=128;AR=48000;P=baseline
#  W=1024;H=576;R=25;BV=2000;BA=96;AR=44100;P=baseline"

rates="
  N=p10;BV=32;R=5;P=baseline;W=224;H=126;BA=24;AR=22050
  N=p20;BV=128;R=12.5;P=baseline;level=3;W=400;H=224;BA=48;AR=44100
  N=p30;BV=304;R=25;P=baseline;level=3;W=400;H=224;BA=64;AR=44100
  N=p40;BV=400;R=25;P=main;level=3;W=512;H=288;BA=96;AR=44100
  N=p50;BV=700;R=25;P=main;level=3;W=640;H=360;BA=96;AR=44100
  N=p60;BV=1200;R=25;P=main;level=3;W=704;H=396;BA=96;AR=44100
  N=p70;BV=2016;R=25;P=main;level=3.1;W=1024;H=576;BA=96;AR=44100
  N=p80;BV=3372;R=25;P=high;level=4;W=1280;H=720;BA=128;AR=44100
  N=p90;BV=5100;R=25;P=high;level=4;W=1920;H=1080;BA=192;AR=48000"

#rates="
#  N=p90;BV=5100;R=25;P=high;level=4;W=1920;H=1080;BA=192;AR=48000"

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
    extra="$extra -i $dog -r:v 25 -filter_complex overlay=40:40"
  fi
  if [ "$deinterlace" ]; then
    extra="$extra -filter:v yadif"
  fi
  # Make it 16x9
  pad="pad=ih*16/9:ih:(ow-iw)/2:(oh-ih)/2"
  pixfmt="-pix_fmt yuv420p "
  pipefmt="avi"
  mkfifo $fifo
  {
    set -x
    ffmpeg -vsync cfr  -y -i "$source" -r:v 25 -r:a 48000 \
      -s 1920x1080 -vf "$pad" $extra \
      -map 0:0 -map 0:1 \
      -acodec pcm_s16le -vcodec rawvideo \
      $pixfmt -f $pipefmt "$fifo"
  } > "$log" 2>&1 &
  tokill="$! $tokill"
  source="$fifo"
fi

tees="cat '$source'"
for rt in $rates; do
  N=; W=; H=; R=; BV=; BA=; P=; AR=
  eval $rt

  pfx="$outfile-$N"
  frag="$pfx/%08d.ts"


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

  echo "Encoding bit rate $N ($S, ${BV}k)"
  mkdir -p "$pfx"
  fifo="$work/br.$N.fifo"
  log="$logs/ffmpeg.$N.log"
  fifos="$fifos $fifo"
  tees="$tees | tee $fifo"
  mkfifo $fifo
  {
    set -x
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
