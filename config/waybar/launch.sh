#!/bin/bash
# Launch waybar with dual bars (top and bottom)

# Kill any existing waybar instances
killall waybar 2>/dev/null

# Wait a moment for processes to terminate
sleep 0.5

# Launch top bar
waybar -c ~/achyprconfig/config/waybar/config-top -s ~/achyprconfig/config/waybar/style.css &

# Launch bottom bar
waybar -c ~/achyprconfig/config/waybar/config-bottom -s ~/achyprconfig/config/waybar/style.css &

echo "Waybar launched with dual bars (top and bottom)"
