#!/bin/bash

FOCUSED_WINDOW=$(xdotool getactivewindow)

WINDOW_TITLE=$(xdotool getwindowname $FOCUSED_WINDOW)

send_nvim_command() {
  NVIM_SERVER=$(ps -o command= -p $(xdotool getwindowpid $1) | grep -oP 'NVIM_LISTEN_ADDRESS=\K\S+')
  if [ -n "$NVIM_SERVER" ]; then
    # Use nvim --servername and --remote-send to send the navigation command
    nvim --servername $NVIM_SERVER --remote-send "<C-w>h"
    exit 0
  fi
}

# Check if the focused window's class indicates it's a terminal
if [[ $WINDOW_TITLE == *"nvim!"* ]]; then
  send_nvim_command $FOCUSED_WINDOW
  exit 0
fi

if [[ $WINDOW_TITLE == *"tmux"* ]]; then
  if tmux display-message -p '#{pane_at_left}' | grep 0; then
    tmux select-pane -L
    exit 0
  fi
fi

# If not in tmux or no pane to the left, focus left in i3
i3-msg focus left
