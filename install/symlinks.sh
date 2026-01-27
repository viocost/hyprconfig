#!/bin/env bash

# Symlinks script for hyprconfig
# Links configuration files from repo to their proper locations

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

# Configurations that should be copied instead of symlinked
COPY_CONFIGS=("nvim" "tmux")

function makedir() {
  if [[ ! -d $1 ]]; then
    mkdir -p $1
  fi
}

echo "Creating directories..."
makedir ~/.local/bin
makedir ~/.config

echo "Linking scripts..."
rm -rf ~/.local/bin/scripts 2>/dev/null
ln -s "$REPO_ROOT/scripts" ~/.local/bin/

echo "Linking zsh configuration..."
rm -rf ~/.zshrc 2>/dev/null
ln -s "$REPO_ROOT/zsh/zshrc" ~/.zshrc

rm -rf ~/.config/aliasrc 2>/dev/null
ln -s "$REPO_ROOT/zsh/aliasrc" ~/.config/

echo "Processing config directory..."

# Iterate through all directories in config/
for config_dir in "$REPO_ROOT/config"/*; do
  if [[ -d "$config_dir" ]]; then
    config_name=$(basename "$config_dir")
    target_path="$HOME/.config/$config_name"
    
    # Remove existing target
    rm -rf "$target_path" 2>/dev/null
    
    # Check if this config should be copied instead of symlinked
    if [[ " ${COPY_CONFIGS[@]} " =~ " ${config_name} " ]]; then
      echo "Copying $config_name configuration..."
      cp -r "$config_dir" "$target_path"
    else
      echo "Linking $config_name configuration..."
      ln -s "$config_dir" "$target_path"
    fi
  fi
done

# Link assets if directory exists
if [[ -d "$REPO_ROOT/assets" ]]; then
  echo "Linking assets..."
  rm -rf ~/.config/assets 2>/dev/null
  ln -s "$REPO_ROOT/assets" ~/.config/
fi

echo ""
echo "Symlinks created successfully!"
echo "Note: ${COPY_CONFIGS[*]} are copied (not symlinked) to allow local modifications"
