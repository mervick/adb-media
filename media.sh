#!/usr/bin/env bash

adb="$(which adb)"
[[ ! "$adb" ]] && adb=~/Android/Sdk/platform-tools/adb
notify=false
driver='notify-send'
icon='audio-headphones'

if [[ "${1::1}" != '-' ]]; then
  command=$1
  shift
fi

while [[ $# > 0 ]]; do
  case $1 in
    -h|--help)
      read -r -d '' help <<- EOM
DESCRIPTION
    Send media keys to the Android device via adb

USAGE
    bash play.sh <command> [-n[=<driver>]|--notification[=<driver>]]
      [-a <app>|-id <app>|--app=<app>] [-i <icon>|--icon=<icon>] [-h|--help]

ARGUMENTS
    command (play|pause|stop|next|prev|rewind|forward|mute|up|down|info)
      play      - play/pause song
      pause     - play/pause song
      stop      - stop paying song
      next      - play next song
      prev      - play previous song
      forward   - fast forward 10 seconds
      rewind    - rewind 10 seconds
      mute      - mute/unmute sound
      up        - set volume up
      down      - set volume down
      info      - get current media info

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
    --debug)
      debug=$1
    ;;
    --app=*)
      app="${1#*=}"
    ;;
  esac
  shift
done

if [[ ! $app ]]; then
  re='Audio playback\s[^¤]*packages=([a-zA-Z0-9\.\-]+)'
  dump="$($adb shell dumpsys media_session)"
  [[ $? != 0 ]] && exit 10
  app="$(echo "$dump" | perl -n00e 's/'"$re"'/\$1/m && print "$1";')"
fi

volume=false

if [[ "$command" == "" ]]; then
    (1>&2 echo 'Command is required')
    exit 7
else
  case "$command" in
    play|pause|play-pause)
      $adb shell media dispatch play-pause
    ;;
    stop|next|previous|fast-forword|mute)
      $adb shell media dispatch "$command"
    ;;
    prev)
      $adb shell media dispatch previous
    ;;
    forword)
      $adb shell media dispatch fast-forword
    ;;
    up)
      $adb shell media volume --adj raise
      volume=true
    ;;
    down)
      $adb shell media volume --adj lower
      volume=true
    ;;
    info)
      info=true
    ;;
    *)
      (1>&2 echo "Invalid command $command")
      exit 8
  esac
fi

if ${notify} || [[ $info ]] ; then
  SOURCE="${BASH_SOURCE[0]}"
  while [[ -h "$SOURCE" ]]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

  if [[ "$driver" || $info ]]; then
    if ${volume}; then
      volume=$(bash "$DIR/get-volume-level.sh" -d=headset -p); err=$?
      [[ $err != 0 ]] && exit $err
      notify_args=("Android volume $volume%" -i "$icon")
    else
      sleep .5
      data="$(bash "$DIR/get-notification.sh" --app="$app" -d ' ### ')"; err=$?
      [[ $err != 0 ]] && exit $err
      title="${data##* ### }"
      [[ "$title" == "" ]] && exit 0
      artist="${data%% ### *}"

      if ${notify}; then
        readarray -t data <<< "$(php "$DIR/parse-rhythmbox.php" "$artist" "$title" "$debug")"

        [[ "$debug" ]] && echo "rhytmbox data ${data[@]}"

        if [[ "${data[3]}" ]]; then
          icon="${data[3]}"
        fi
        if [[ "${data[2]}" ]]; then
          artist="$artist\n<i>from</i> ${data[2]}"
        fi
      fi
      notify_args=("$title" "$artist" -i "$icon")
    fi
  fi

  if ${notify}; then
    case "$driver" in
      notify-send)
        pkill notify-osd
        notify-send "${notify_args[@]}"
      ;;
    esac
  elif ${info}; then
    echo "$artist - $title"
  fi
fi
