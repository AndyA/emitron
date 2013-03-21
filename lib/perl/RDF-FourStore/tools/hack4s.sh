#!/bin/bash

bindir="bin4s"
tmpdat="/tmp/4s.d"
tmplog="/tmp/4s.l"
mkdir -p "$bindir"

fs_backend=$( which 4s-backend ) || {
  echo "Can't find 4s-backend" 1>&2
  exit 1
}

datadir="$( strings "$fs_backend" | \
  perl -lne 'print $1 if m{^(/.+)/%s/metadata.nt}' )" || {
  echo "Can't find data directory" 1>&2
  exit 1
}

while [ ${#tmpdat} -lt ${#datadir} ]; do tmpdat="${tmpdat}_"; done

fs_httpd=$( which 4s-httpd ) || {
  echo "Can't find 4s-httpd" 1>&2
  exit 1
}

logdir="$( strings "$fs_httpd" | \
  perl -lne 'print $1 if m{^(/.+)/query-%s.log}' )" || {
  echo "Can't find log directory" 1>&2
  exit 1
}

while [ ${#tmplog} -lt ${#logdir} ]; do tmplog="${tmplog}_"; done

mkdir -p "$tmpdat" "$tmplog"

fs_dir="$( dirname "$fs_backend" )"
find "$fs_dir" -maxdepth 1 -name '4s-*' | while read bin; do
  dst="$bindir"/"$( basename "$bin" )"
  [ "$bin" -nt "$dst" ] \
    && perl -pe "s@$datadir@$tmpdat@g; s@$logdir@$tmplog@g" < "$bin" > "$dst"
  chmod a+x "$dst"
done

echo "$tmpdat";

# vim:ts=2:sw=2:sts=2:et:ft=sh

