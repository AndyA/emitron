#!/bin/bash

./auto/configure \
  --prefix=$PWD/../.. \
  --add-module=$PWD/../nginx-rtmp-module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_ssl_module

# vim:ts=2:sw=2:sts=2:et:ft=sh

