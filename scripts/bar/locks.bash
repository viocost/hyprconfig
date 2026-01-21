#!/bin/env bash

# yet to be implemented

CAPS=$(xset -q | grep Caps | awk '{print $4}')
NUM=$(xset -q | grep Caps | awk '{print $8}')

function status() {
  if [[ $2 == "on" ]]; then
    echo "<span background=\"#0068a0\" font_size=\"x-small\"> $1 </span>"
  else
    echo "<span foreground=\"#666\"  font_size=\"x-small\"> $1 </span>"
  fi
}

echo $(status CAPS $CAPS)
