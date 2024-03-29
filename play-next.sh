#!/usr/bin/env bash

adb=~/Android/Sdk/platform-tools/adb
notify=false
driver='notify-send'
icon='audio-headphones'

while [[ $# > 0 ]]; do
  case $1 in
    -h|--help)
      read -r -d '' help <<- EOM
DESCRIPTION
    Play next song at the Android device via adb

USAGE
    bash play-next.sh [-n[=<driver>]|--notification[=<driver>]]
      [-a <app>|-id <app>|--app=<app>] [-i <icon>|--icon=<icon>] [-h|--help]

OPTIONS
    -n[=<driver>], --notification[=<driver>]
      Show notification using specified driver. Currently supported drivers:
      'notify-send'. By default is '${driver}'

    -a <app>, -id <app>, --app=<app>
      Select notification application. By default detects last played application'

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
    -a|-id)
      if [[ $# > 1 ]]; then
        shift
        app="$1"
      else
        (1>&2 echo 'Application name is required')
        exit 2
      fi
    ;;
    --app=*)
      app="${1#*=}"
    ;;
  esac
  shift
done

if [[ ! $app ]]; then
  re='Audio playback\s[^¤]*packages=([a-zA-Z0-9\.\-]+)'
  app="$($adb shell dumpsys media_session | perl -n00e 's/'"$re"'/\$1/m && print "$1";')"
fi

# send command to android to play next song
$adb shell input keyevent 87

if ${notify}; then
  SOURCE="${BASH_SOURCE[0]}"
  while [[ -h "$SOURCE" ]]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

  case "$driver" in
    notify-send)
      sleep .5

      data="$(bash "$DIR/get-notification.sh" --app="$app" -d ' ### ')"
      text="${data%% ### *}"
      title="${data##* ### }"

      pkill notify-osd
      if [[ "$text" != "$title" ]]; then
        notify-send "$text" "$title" -i "$icon"
      else
        notify-send "$title" -i "$icon"
      fi
    ;;
  esac
fi
