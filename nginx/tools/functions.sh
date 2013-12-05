#!/bin/bash

function kill_wait {
  local pid="$1"
  kill -0 $pid > /dev/null 2>&1 || return
  echo "Killing $pid"
  while kill $pid > /dev/null 2>&1; do
    sleep 1
  done
}

function singleton {
  local name="$1"
  pidfile="/tmp/$name.pid"
  if [ -e "$pidfile" ]; then
    pid=$( cat "$pidfile" )
    kill_wait $pid
  fi
  echo -n $$ > "$pidfile"
}

# vim:ts=2:sw=2:sts=2:et:ft=sh

