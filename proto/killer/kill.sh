#!/bin/bash

ps ax | grep 'perl killer\.pl' | grep -v grep | f 0 | while read pid; do kill -9 $pid; done
