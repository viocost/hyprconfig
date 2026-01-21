#!/bin/bash

TEXT='#8bc34a'
timeout=60
img=~/wallpapers/0311.jpg
i3lock -f --keylayout 1 -i $img -t --verif-color=$TEXT --wrong-color=$TEXT --time-color=$TEXT --date-color=$TEXT --layout-color=$TEXT &
while [ $(pgrep i3lock | wc -l) -ne 0 ]; do
  sleep $timeout

  idle_time=$(xprintidle)
  idle_time_sec=$((idle_time / 1000))

  if [ $(pgrep i3lock | wc -l) -ne 0 ] && [ "$idle_time_sec" -gt $timeout ]; then
    xset dpms force off
  fi
done
