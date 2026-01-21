#!/bin/bash

FOCUSED_WINDOW=$(xdotool getactivewindow)

WINDOW_TITLE=$(xdotool getwindowname $FOCUSED_WINDOW)
if [[ $WINDOW_TITLE == *"tmux"* ]]; then
  if tmux display-message -p '#{pane_at_right}' | grep 0; then
    tmux select-pane -R
    exit 0
  fi
fi

i3-msg focus right
