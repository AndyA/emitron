#!/bin/bash

root=$PWD/4s

fs_backend_setup=$( which 4s-backend-setup ) || {
  echo "Can't find 4s-backend-setup" 1>&2
  exit 1
}

mkdir -p "$root/dev"
mkdir -p "$root/var/lib/4store"

sudo mknod "$root/dev/random" c 1 8 
sudo mknod "$root/dev/urandom" c 1 9 

function mirror {
  local src=$1

  dst="$root$src"
  [ -e "$dst" ] && return
  echo "$src -> $dst"
  mkdir -p "$( dirname "$dst" )"
  cp -uL "$src" "$dst"
}

ldd "$fs_backend_setup" \
  | perl -lne 'print $1 if m{\s(/\S+)}' \
  | while read dep; do
  if [ -e "$dep" ]; then
    mirror "$dep"
  fi
done

mirror "$fs_backend_setup"

# vim:ts=2:sw=2:sts=2:et:ft=sh

