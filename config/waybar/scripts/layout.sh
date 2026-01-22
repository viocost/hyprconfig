#!/usr/bin/env bash
# Keyboard Layout Module with Flag Icons
# Subscribes to Hyprland layout changes

trap 'exit' INT TERM
trap 'kill 0' EXIT

# Map layout names to flags and short codes
get_layout_display() {
  local layout="$1"

  case "$layout" in
  *"English (US)"* | *"English"*)
    echo '{"text": "🇺🇸 US", "tooltip": "English (US)", "class": "us"}'
    ;;
  *"Russian"* | *"ru"*)
    echo '{"text": "🇷🇺 RU", "tooltip": "Russian", "class": "ru"}'
    ;;
  *"Hebrew"* | *"il"* | *"he"*)
    echo '{"text": "🇮🇱 IL", "tooltip": "Hebrew", "class": "il"}'
    ;;
  *)
    # Default fallback
    echo "{\"text\": \"⌨ $layout\", \"tooltip\": \"$layout\", \"class\": \"unknown\"}"
    ;;
  esac
}

handle() {
  case $1 in
  activelayout*)
    # Extract layout name from the event
    layout=$(echo "$1" | sed 's/^activelayout>>//' | awk -F',' '{print $2}')
    get_layout_display "$layout"
    ;;
  esac
}

# Get initial layout
initial_layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.name != "virtual-keyboard-1") | .active_keymap' | head -1)
get_layout_display "$initial_layout"

# Subscribe to layout changes via Hyprland socket
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  handle "$line"
done
