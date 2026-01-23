#!/bin/bash

# Hyprland Screenshot Script with Rofi Menu
# Dependencies: hyprshot, rofi, notify-send, swappy

# Screenshot directory
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Path to hyprshot script
HYPRSHOT="$HOME/hyprconfig/scripts/hyprshot.sh"

# Rofi menu options
OPTIONS="🔳 Active Window\n✂️ Select Region\n🖥️ Active Monitor\n🪟 Full Desktop"

# Show rofi menu and get selection
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Screenshot" -theme-str 'window {width: 300px;}' -theme-str 'listview {lines: 4;}')

# Exit if no selection
if [ -z "$CHOICE" ]; then
    exit 0
fi

# Generate filename with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="screenshot_${TIMESTAMP}.png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"

# Function to send notification with edit button and thumbnail
send_notification() {
    local filepath="$1"
    
    echo $filepath
    # Wait a moment for file to be fully written
    sleep 0.2
    
    # Verify file exists
    if [ ! -f "$filepath" ]; then
        notify-send "Screenshot Error" "File not found: $filepath" --urgency=critical
        return 1
    fi
    
    # Send notification with thumbnail, clipboard info, and action button in background
    # Using image-path hint for swaync to display the screenshot thumbnail
    (
        local message="Image saved and copied to the clipboard.\n\nPath: <i>${filepath}</i><img src=\"${filepath}\">"
        ACTION=$(notify-send "📸 Screenshot saved" \
            "${message}" \
            -t 5000 \
            -a "Screenshot" \
            --action="edit=Edit" \
            --urgency=normal)
        
        # If user clicked Edit, open swappy
        if [ "$ACTION" = "edit" ]; then
            swappy -f "$filepath" &
        fi
    ) &
}

# Take screenshot based on choice
case "$CHOICE" in
    *"Active Window"*)
        # Take screenshot of active window
        "$HYPRSHOT" -m active -m window -o "$SCREENSHOT_DIR" -f "$FILENAME" -s
        
        if [ $? -eq 0 ]; then
            send_notification "$FILEPATH"
        else
            notify-send "Screenshot Failed" "Could not capture active window" --urgency=critical
        fi
        ;;
        
    *"Select Region"*)
        # Take screenshot of selected region
        "$HYPRSHOT" -m region -o "$SCREENSHOT_DIR" -f "$FILENAME" -s
        
        if [ $? -eq 0 ]; then
            send_notification "$FILEPATH"
        else
            # User might have cancelled selection
            exit 0
        fi
        ;;
        
    *"Active Monitor"*)
        # Take screenshot of active monitor
        "$HYPRSHOT" -m active -m output -o "$SCREENSHOT_DIR" -f "$FILENAME" -s
        
        if [ $? -eq 0 ]; then
            send_notification "$FILEPATH"
        else
            notify-send "Screenshot Failed" "Could not capture active monitor" --urgency=critical
        fi
        ;;
        
    *"Full Desktop"*)
        # Take screenshot of all outputs
        "$HYPRSHOT" -m output -o "$SCREENSHOT_DIR" -f "$FILENAME" -s
        
        if [ $? -eq 0 ]; then
            send_notification "$FILEPATH"
        else
            notify-send "Screenshot Failed" "Could not capture full desktop" --urgency=critical
        fi
        ;;
        
    *)
        exit 0
        ;;
esac
