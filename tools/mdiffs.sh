#!/bin/bash

model="$1"

prev=""
find "$model" -name '*.json' | sort -V | while read rev; do
  if [ "$prev" ]; then
    echo "$prev --> $rev"
    diff -u <( jsontidy "$prev" ) <( jsontidy "$rev" )
  fi
  prev="$rev"
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

