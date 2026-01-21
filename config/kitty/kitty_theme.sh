#!/bin/bash

function kittychange() {
  # Store the paths
  local config_dir="$HOME/.config/kitty"
  local themes_dir="$config_dir/kitty-themes/themes"
  local theme_symlink="$config_dir/theme.conf"

  # Check if required directories exist
  if [[ ! -d "$config_dir" ]]; then
    echo "Error: Kitty config directory not found at $config_dir"
    return 1
  fi

  if [[ ! -d "$themes_dir" ]]; then
    echo "Error: Themes directory not found at $themes_dir"
    return 1
  fi

  # Use fzf to select a theme
  local selected_theme=$(find "$themes_dir" -type f -name "*.conf" -exec basename {} \; |
    fzf --preview "bat --color=always --style=plain $themes_dir/{}" \
      --preview-window=right:70%)

  # Check if a theme was selected
  if [[ -z "$selected_theme" ]]; then
    echo "No theme selected"
    return 0
  fi

  # Remove existing symlink if it exists
  if [[ -L "$theme_symlink" ]]; then
    rm "$theme_symlink"
  elif [[ -e "$theme_symlink" ]]; then
    echo "Warning: $theme_symlink exists but is not a symlink"
    return 1
  fi

  # Create new symlink
  ln -s "$themes_dir/$selected_theme" "$theme_symlink"

  echo "Theme switched to: $selected_theme"

  # Optionally reload kitty configuration
  if command -v kitty &>/dev/null; then
    kitty @ set-colors --all "$theme_symlink"
    echo "Kitty colors reloaded"
  fi
}
