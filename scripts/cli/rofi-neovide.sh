#!/bin/bash

# Find all nvim sockets in /tmp
SOCKETS=$(ls /tmp/nvim_*.sock 2> /dev/null)

if [ -z "$SOCKETS" ]; then
    notify-send "Neovim" "No active sessions found."
    exit 0
fi

# Clean up the names for the Rofi menu
# Shows "ProjectName" instead of "/tmp/nvim_home_user_ProjectName.sock"
CHOICE=$(echo "$SOCKETS" | sed 's|/tmp/nvim_||;s|.sock||' | rofi -dmenu -i -p "Attach Neovide")

if [ -n "$CHOICE" ]; then
    SELECTED_SOCKET="/tmp/nvim_$CHOICE.sock"
    neovide --server "$SELECTED_SOCKET" > /dev/null 2>&1 &
    disown
fi
