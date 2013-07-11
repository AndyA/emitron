#!/bin/bash

pid="v0001phs"

for b in {1..3}; do
  s3cmd del -r s3://thespace-media-live/$pid/mag${b} 
  s3cmd del s3://thespace-media-live/$pid/mag${b}.m3u8
done
s3cmd del s3://thespace-media-live/$pid/$pid.m3u8


# vim:ts=2:sw=2:sts=2:et:ft=sh

