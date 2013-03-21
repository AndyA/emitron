#!/bin/bash

bindir="bin4s"
tmpdir="/tmp/4s.tmp"
mkdir -p "$bindir"

fs_backend_setup=$( which 4s-backend ) || {
  echo "Can't find 4s-backend" 1>&2
  exit 1
}

datadir="$( strings "$fs_backend_setup" | \
  perl -lne 'print $1 if m{^(/.+)/%s/metadata.nt}' )" || {
  echo "Can't find data directory" 1>&2
  exit 1
}

while [ ${#tmpdir} -lt ${#datadir} ]; do tmpdir="${tmpdir}_"; done

mkdir -p "$tmpdir"

fs_dir="$( dirname "$fs_backend_setup" )"
find "$fs_dir" -maxdepth 1 -name '4s-*' | while read bin; do
  dst="$bindir"/"$( basename "$bin" )"
  [ "$bin" -nt "$dst" ] && perl -pe "s@$datadir@$tmpdir@g" < "$bin" > "$dst"
  chmod a+x "$dst"
done


# vim:ts=2:sw=2:sts=2:et:ft=sh

