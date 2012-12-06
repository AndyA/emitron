#!/bin/bash

bindir="$( dirname "$0" )"
port=3000
workers=10

plackup -E deployment -s Starman --workers=$workers -p $port -a "$bindir/app.pl"

# vim:ts=2:sw=2:sts=2:et:ft=sh

