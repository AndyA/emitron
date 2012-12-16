#!/bin/bash

cd "$( dirname "$0" )"

for d in fatcat spliff tailpipe; do
  make -C $d install
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

