#!/bin/bash
# Launch waybar with workspace assignments per monitor

# Kill any existing waybar instances
killall waybar 2>/dev/null

# Wait a moment for processes to terminate
sleep 0.5

# Monitor variables
MONITOR_LEFT="DP-1"      # Workspaces 1-8
MONITOR_MIDDLE="DP-4"    # Workspaces 9-16
MONITOR_RIGHT="eDP-1"    # Workspaces 17-20

# Launch top bar
waybar -c ~/.config/waybar/config-top -s ~/.config/waybar/style.css &

# Launch bottom bar (single instance handles all monitors)
waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style.css &

echo "Waybar launched with workspace assignments:"
echo "  - $MONITOR_LEFT: workspaces 1-8"
echo "  - $MONITOR_MIDDLE: workspaces 9-16"
echo "  - $MONITOR_RIGHT: workspaces 17-20"

