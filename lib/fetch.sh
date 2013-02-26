#!/bin/bash

cd "$( dirname "$0" )"

[ -d jsondata -a -d jsondata/.git ] || {
  rm -rf jsondata
  git clone git@github.com:AndyA/jsondata.git jsondata
}

# vim:ts=2:sw=2:sts=2:et:ft=sh

