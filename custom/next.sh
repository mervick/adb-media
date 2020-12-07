#!/usr/bin/env bash

[[ $(ps ax | grep rhythmbox | grep -v grep) ]] && rhythmbox-client --next || /home/data/projects/shell/adb-media/media.sh next -n
