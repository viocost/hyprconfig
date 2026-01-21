#!/bin/bash

# Function to send command to Neovim
send_nvim_command() {
  NVIM_SERVER=$(ps -o command= -p $(xdotool getwindowpid $1) | grep -oP 'NVIM_LISTEN_ADDRESS=\K\S+')
  if [ -n "$NVIM_SERVER" ]; then
    # Use nvim --servername and --remote-send to send the navigation command
    nvim --servername $NVIM_SERVER --remote-send "<C-w>h"
    exit 0
  fi
}

# Get the ID of the currently focused window
FOCUSED_WINDOW=$(xdotool getactivewindow)

# Get the class of the focused window
WINDOW_NAME=$(xdotool getwindowname $FOCUSED_WINDOW)

# Check if the focused window's class indicates it's a terminal
if [[ $WINDOW_NAME == *"nvim"* ]]; then
  send_nvim_command $FOCUSED_WINDOW
fi
