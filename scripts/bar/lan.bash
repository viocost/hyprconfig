#!/usr/bin/env bash


IP=$(ip a | grep -E "inet.*enp11s0" | cut -d' '  -f6 | sed 's/\/.*//')

if [[ $IP ]]; then
  echo "<span foreground=\"#01c64d\"></span> <span foreground=\"#EBDBB2\">$IP</span>"
else
  echo "<span foreground=\"#777\"><s></s></span> <span foreground=\"#9e0113\"><i>disconnected</i></span>"
fi
