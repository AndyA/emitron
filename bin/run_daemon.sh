#!/bin/sh
./evostreamms --daemon --uid=`id -u evostream` --gid=`cat /etc/group|grep evostreamms | awk -F ":" '{print $3}'` --pid=/var/run/evostreamms.pid ../config/config.lua

