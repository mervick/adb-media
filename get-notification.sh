#!/usr/bin/env bash

adb="$(which adb)"
[[ ! "$adb" ]] && adb=~/Android/Sdk/platform-tools/adb
delimiter=' - '

while [[ $# > 0 ]]; do
  case $1 in
    -h|--help)
      read -r -d '' help <<- EOM
DESCRIPTION
    Get notification from Android device via adb by application id

USAGE
    bash get-notification.sh [-a <app>|-id <app>|--app=<app>]
      [-d <delimiter>|--delimiter=<delimiter>] [-h|--help]

OPTIONS
    -a <app>, -id <app>, --app=<app>
      Select notification application. By default detects last played application'

    -d <delimiter>, --delimiter=<delimiter>
      Print delimiter. Default is '${delimiter}'

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
    -a)
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
    -d)
      if [[ $# > 1 ]]; then
        shift
        delimiter="$1"
      fi
    ;;
    -d=*|--delimiter=*)
      delimiter="${1#*=}"
    ;;
  esac
  shift
done

if [[ ! "$app" ]]; then
  re='Audio playback\s[^¤]*packages=([a-zA-Z0-9\.\-]+)'
  app="$($adb shell dumpsys media_session | perl -n00e 's/'"$re"'/\$1/m && print "$1";')"
fi

app="$(echo "$app" | sed 's/\./\\./g')"

re='\sNotificationRecord\(.*?pkg='"$app"'\s[^¤]*?extras=\{[^¤]*?android\.title\=([^\n]*)[^¤]*?android\.text\=([^\n]*)[^¤]*?\s{4}\}'
data=$($adb shell dumpsys notification --noredact | sed -e 's/NotificationRecord/¤ NotificationRecord/g'\
 | perl -n00e 's/'"$re"'/\$1/gm && print "$2 ### $1\n";')

text="${data%% ### *}"
title="${data##* ### }"

text2="${text#*String \(}"
title2="${title#*String \(}"

if [[ "$text2" != "$text" ]]; then
  echo -n "${text2%\)*}"
fi

if [[ "$text2" != "$text" ]] && [[ "$title2" != "$title" ]]; then
  echo -n "$delimiter"
fi

if [[ "$title2" != "$title" ]]; then
  echo -n "${title2%\)*}"
fi

echo
