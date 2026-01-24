#!/bin/env bash

# Symlinks script for hyprconfig
# Links configuration files from repo to their proper locations

cd ..

function makedir() {
  if [[ ! -d $1 ]]; then
    mkdir -p $1
  fi
}

function rmquiet() {
  rm $1 -rf 2>/dev/null
}

echo "Creating directories..."
makedir ~/.local/bin
makedir ~/.config

echo "Linking scripts..."
rmquiet ~/.local/bin/scripts
ln -s $(pwd)/scripts $(readlink -f ~/.local/bin)

echo "Linking zsh configuration..."
rmquiet ~/.zshrc
ln -s $(pwd)/zsh/zshrc $(readlink -f ~/.zshrc)

rmquiet ~/.config/aliasrc
ln -s $(pwd)/zsh/aliasrc $(readlink -f ~/.config)

rmquiet ~/.config/aliases
ln -s $(pwd)/config/aliases $(readlink -f ~/.config)

echo "Linking Hyprland configuration..."
rmquiet ~/.config/hypr
ln -s $(pwd)/config/hypr $(readlink -f ~/.config)

echo "Linking waybar configuration..."
rmquiet ~/.config/waybar
ln -s $(pwd)/config/waybar $(readlink -f ~/.config)

echo "Linking rofi configuration..."
rmquiet ~/.config/rofi
ln -s $(pwd)/config/rofi $(readlink -f ~/.config)

echo "Linking kitty configuration..."
rmquiet ~/.config/kitty
ln -s $(pwd)/config/kitty $(readlink -f ~/.config)

echo "Linking fastfetch configuration..."
rmquiet ~/.config/fastfetch
ln -s $(pwd)/config/fastfetch $(readlink -f ~/.config)

echo "Copying nvim configuration..."
rmquiet ~/.config/nvim
cp -r $(pwd)/config/nvim $(readlink -f ~/.config)/nvim

echo "Copying tmux configuration..."
rmquiet ~/.config/tmux
cp -r $(pwd)/config/tmux $(readlink -f ~/.config)/tmux

echo "Linking assets..."
rmquiet ~/.config/assets
ln -s $(pwd)/assets $(readlink -f ~/.config)

echo ""
echo "Symlinks created successfully!"
echo "Note: nvim and tmux are copied (not symlinked) to allow local modifications"
