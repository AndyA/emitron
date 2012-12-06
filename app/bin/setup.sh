#!/bin/bash

home="$( dirname "$0" )/.."

# Get fonts
fonts="$home/fonts"
font="Envy Code R.ttf"
base="http://download.damieng.com/fonts/original"
zip="EnvyCodeR-PR7.zip"

[ -f "$fonts/$font" ] || {
  mkdir -p "$fonts" && cd "$fonts"
  uri="$base/$zip"
  wget -c "$uri" && unzip "$zip" && {
    find . -name "$font" -type f | while read ff; do
      [ -e "$font" ] || mv "$ff" "$font"
    done
  }
  find . -maxdepth 1 -mindepth 1 \( -name '*.zip' -o -type d \) -print0 | xargs -0 rm -rf
}

# vim:ts=2:sw=2:sts=2:et:ft=sh

