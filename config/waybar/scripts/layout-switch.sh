#!/usr/bin/env bash
# Switch keyboard layout for all keyboards

# Get all keyboard names (excluding special devices)
keyboards=$(hyprctl devices -j | jq -r '.keyboards[] | select(.name | test("video-bus|power-button|sleep-button|system-control|consumer-control") | not) | .name')

# Switch layout for each keyboard
while IFS= read -r kb; do
    if [[ -n "$kb" ]]; then
        hyprctl switchxkblayout "$kb" next
    fi
done <<< "$keyboards"
