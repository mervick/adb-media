#!/usr/bin/env bash

adb=/home/izman/Android/Sdk/platform-tools/adb
notify=false
driver='notify-send'
icon='audio-headphones'

while [[ $# > 0 ]]; do
  case $1 in
    -h|--help)
      read -r -d '' help <<- EOM
DESCRIPTION
    Decrease volume of Android device via adb

USAGE
    bash set-volume-down.sh [-n[=<driver>]||--notification[=<driver>]]
      [-i <icon>|--icon=<icon>] [-h|--help]

OPTIONS
    -n[=<driver>], --notification[=<driver>]
      Show notification using specified driver. Currently supported drivers:
      'notify-send'. By default is '${driver}'

    -i <icon>, --icon=<icon>
      Notification icon. Default is '${icon}'

    -h, --help
        Show this help
AUTHOR
    Andrey Izman (c) 2020 <izmanw@gmail.com>

LICENSE
    LGPL v3
EOM
      echo -e "$help"
      exit 0
    ;;
    --notification=*|-n=*)
      notify=true
      driver="${1#*=}"
    ;;
    --notification|-n)
      notify=true
    ;;
    -i)
      if [[ $# > 1 ]]; then
        shift
        icon="$1"
      fi
    ;;
    --icon=*|-i=*)
        icon="${1#*=}"
    ;;
  esac
  shift
done

# send command to android device to down volume
$adb shell input keyevent 25

if ${notify}; then
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

  case "$driver" in
    notify-send)
      pkill notify-osd
      volume=$(bash "$DIR/get-volume-level.sh" -d=headset -p)
      notify-send "Android volume $volume%" -i "$icon"
    ;;
  esac
fi
