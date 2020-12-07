#!/usr/bin/env bash

[[ $(ps ax | grep rhythmbox | grep -v grep) ]] && rhythmbox-client --previous || /home/data/projects/shell/adb-media/media.sh prev -n
