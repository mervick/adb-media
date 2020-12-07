#!/usr/bin/env bash

[[ $(ps ax | grep rhythmbox | grep -v grep) ]] && rhythmbox-client --play-pause || /home/data/projects/shell/adb-media/media.sh pause
