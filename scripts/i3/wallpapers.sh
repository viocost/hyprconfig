#!/usr/bin/env bash

# Wallpaper settings - run in background
wallpaper_file="$CURRENT_WALLPAPER"
monitor_count=$(xrandr --listmonitors | head -n1 | cut -d' ' -f2)
wallpaper_args=""
for ((i = 0; i < monitor_count; i++)); do
  wallpaper_args+="$wallpaper_file "
done
feh --no-fehbg --bg-fill $wallpaper_args
