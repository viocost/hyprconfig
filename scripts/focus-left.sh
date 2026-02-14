#!/bin/bash

ACTIVE_WINDOW_JSON=$(hyprctl activewindow -j)

FOCUSED_PID=$(echo "$ACTIVE_WINDOW_JSON" | jq -r '.pid')
WINDOW_TITLE=$(echo "$ACTIVE_WINDOW_JSON" | jq -r '.title')

send_nvim_command() {
  NVIM_SERVER=$(ps -o command= -p "$FOCUSED_PID" | grep -oP 'NVIM_LISTEN_ADDRESS=\K\S+')
  if [ -n "$NVIM_SERVER" ]; then
    nvim --server "$NVIM_SERVER" --remote-send "<C-w>h"
    exit 0
  fi
}

if [[ $WINDOW_TITLE == *"nvim!"* ]]; then
  send_nvim_command
  exit 0
fi

if [[ $WINDOW_TITLE == *"tmux"* ]]; then
  if tmux display-message -p '#{pane_at_left}' | grep -q 0; then
    tmux select-pane -L
    exit 0
  fi
fi

hyprctl dispatch movefocus l
