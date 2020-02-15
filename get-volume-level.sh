#!/usr/bin/env bash

speaker=volume_ring_speaker
headset=volume_music_headset
percentage=false

# default device
device="active"

while [[ $# > 0 ]]; do
  case $1 in
    -h|--help)
      read -r -d '' help <<- EOM
DESCRIPTION
    Get volume of android device using adb

USAGE
    bash get-volume-level.sh [-d <device>|--device=<device>]
      [-p|--percentage] [-h|--help]

OPTIONS
    -d <device>, --device=<device>
        Get volume of selected device of the connected Android phone. Support
        'speaker', 'headset' and 'active' values. Default value is '${device}'.
        When 'active' value used then script detects active device by parse
        'adb shell dumpsys audio' command

    -p, --percentage
        Show output in percentage

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
    --device=*|-d=*)
      device="${1#*=}"
    ;;
    --device|-d)
      if [[ $# > 1 ]]; then
        shift
        device=$1
      else
        (1>&2 echo 'Device name is required')
        exit 2
      fi
    ;;
    -p|--percentage)
      percentage=true
    ;;
  esac
  shift
done

device="$(echo "$device" | tr '[:upper:]' '[:lower:]')"

while true; do
  case "$device" in
    speaker)
      device="$speaker"
    ;;
    headset)
      device="$headset"
    ;;
    active)
      # get active device
      re='\-\s*STREAM_MUSIC:\n\s*[^\n]*\n[^\n]*\n\s*Max:\s*([0-9]*)\n[^\n]*\n\s*Devices:\s*([a-zA-Z0-9]*)'
      dumpsys="$(adb shell dumpsys audio | grep -zoP "$re")"
      max_volume=$(echo "$dumpsys" | perl -p00e "s/$re/\$1/gm")
      device="$(echo "$dumpsys" | perl -p00e "s/$re/\$2/gm")"
      continue
    ;;
  esac
  break
done

if [[ "$max_volume" == "" ]]; then
  case "$device" in
    "$speaker")
      max_volume=7
    ;;
    "$headset")
      max_volume=15
    ;;
    *)
      (1>&2 echo "Unsupported device '$device'. Currently supports only 'speaker' and 'headset' devices")
      exit 3
    ;;
  esac
fi

# get current volume level of device
volume=$(adb shell settings get system "$device")

if ${percentage}; then
  echo $((volume * 100 / max_volume))
else
  echo "$volume / $max_volume"
fi
