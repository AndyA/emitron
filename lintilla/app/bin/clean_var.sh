#!/bin/bash

find public/asset -type d -name var -print0 | sudo xargs -0 rm -rf

# vim:ts=2:sw=2:sts=2:et:ft=sh

