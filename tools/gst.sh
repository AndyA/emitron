#!/bin/bash

gst-launch 'mpegtsmux name=muxer ! filesink location=hlspipe.ts rtspsrc location=rtsp://newstream.fenkle:5544/phool name=src src. ! rtpmp4gdepay ! queue ! muxer. src. ! rtph264depay ! queue ! muxer.'

# vim:ts=2:sw=2:sts=2:et:ft=sh

