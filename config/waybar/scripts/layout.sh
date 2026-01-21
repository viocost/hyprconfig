#!/bin/bash

# Get keyboard name from config or use default
KEYBOARD_NAME=${KEYBOARD_NAME:-"at-translated-set-2-keyboard"}

# Function to get current layout
get_layout() {
    LAYOUT=$(hyprctl devices -j | jq -r ".keyboards[] | select(.name == \"$KEYBOARD_NAME\") | .active_keymap" 2>/dev/null)
    
    if [ -z "$LAYOUT" ]; then
        # Fallback to first keyboard if specified one not found
        LAYOUT=$(hyprctl devices -j | jq -r '.keyboards[0].active_keymap' 2>/dev/null)
    fi
    
    # Map full names to short codes
    case "$LAYOUT" in
        "English (US)") SHORT="US" ;;
        "Russian") SHORT="RU" ;;
        "Hebrew") SHORT="IL" ;;
        *) SHORT=$(echo "$LAYOUT" | cut -c1-2 | tr '[:lower:]' '[:upper:]') ;;
    esac
    
    echo "$SHORT"
}

# Function to output JSON
output_json() {
    LAYOUT=$(get_layout)
    cat <<EOF
{"text": " $LAYOUT", "tooltip": "Keyboard Layout: $LAYOUT", "class": "layout"}
EOF
}

# Output initial state
output_json

# Try to listen to Hyprland events if socket is available
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    SOCKET_PATH="/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    
    if [ -S "$SOCKET_PATH" ]; then
        # Use nc (netcat) to listen to Hyprland events
        nc -U "$SOCKET_PATH" 2>/dev/null | while read -r line; do
            if echo "$line" | grep -q "activelayout"; then
                output_json
            fi
        done
    else
        # Fallback to polling if socket not available
        LAST_LAYOUT=$(get_layout)
        while true; do
            sleep 0.5
            CURRENT_LAYOUT=$(get_layout)
            if [ "$CURRENT_LAYOUT" != "$LAST_LAYOUT" ]; then
                output_json
                LAST_LAYOUT="$CURRENT_LAYOUT"
            fi
        done
    fi
else
    # Fallback to polling if not running in Hyprland
    LAST_LAYOUT=$(get_layout)
    while true; do
        sleep 0.5
        CURRENT_LAYOUT=$(get_layout)
        if [ "$CURRENT_LAYOUT" != "$LAST_LAYOUT" ]; then
            output_json
            LAST_LAYOUT="$CURRENT_LAYOUT"
        fi
    done
fi
