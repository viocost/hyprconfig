#!/bin/bash

# Main installation script for hyprconfig
# Run this on a fresh Arch Linux system to set up Hyprland environment

echo "=========================================="
echo "  Hyprland Configuration Setup"
echo "=========================================="
echo ""

# Updating arch
echo "📦 Updating the system..."
sleep 1
./run.sh "sudo pacman -Syu --noconfirm"

# Installing software
echo "📦 Installing software packages..."
sleep 1
./run.sh ./install/software.sh

# Configuring git
echo "🔑 Setting up Git and SSH keys..."
sleep 1
./run.sh ./install/git.sh

# Setup fingerprint authentication (if user chose to install it)
if pacman -Qi fprintd &>/dev/null; then
  echo "🔐 Setting up fingerprint authentication..."
  sleep 1
  ./run.sh ./install/fingerprint.sh
fi

# TODO: Add more installation steps as we build them
# - Fonts
# - Symlinks
# - Cron jobs
# - Services

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
read -p "Installation completed. Reboot now? (y/N) " answer
if [[ "${answer,,}" =~ ^y(es)?$ ]]; then
  sudo reboot now
else
  echo "Reboot cancelled. Please reboot manually to complete setup."
fi
