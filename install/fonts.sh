#!/bin/env bash

# Fonts installation script
# Clones and installs fonts from private GitLab repository

curdir=$(pwd)

echo "=========================================="
echo "  Font Installation"
echo "=========================================="
echo ""
echo "⚠️  This requires SSH access to gitlab.com:viocost/arch-fonts"
echo "   Make sure git.sh has been run successfully first!"
echo ""

# Check if SSH key is configured
if [ ! -f ~/.ssh/dev_key ] && [ ! -f ~/.ssh/id_rsa ]; then
  echo "❌ Error: No SSH key found in ~/.ssh/"
  echo "   Please run git.sh first to set up SSH keys"
  echo ""
  read -p "Skip font installation? (Y/n): " answer
  if [[ ! "${answer,,}" =~ ^n(o)?$ ]]; then
    echo "Skipping font installation..."
    exit 0
  fi
fi

# Test SSH connection
echo "Testing SSH connection to GitLab..."
if ! ssh -T git@gitlab.com 2>&1 | grep -q "Welcome to GitLab"; then
  echo "⚠️  Warning: Cannot connect to GitLab via SSH"
  echo "   This may fail if SSH keys are not set up correctly"
  echo ""
  read -p "Continue anyway? (y/N): " answer
  if [[ ! "${answer,,}" =~ ^y(es)?$ ]]; then
    echo "Skipping font installation..."
    exit 0
  fi
fi

echo "📦 Cloning font repository..."
if git clone git@gitlab.com:viocost/arch-fonts ~/arch-fonts; then
  cd ~/arch-fonts
  
  echo "📦 Installing fonts..."
  ./install.sh
  
  cd "$curdir"
  rm -rf ~/arch-fonts
  
  echo "✓ Fonts installed successfully"
else
  echo "❌ Failed to clone font repository"
  echo "   Skipping font installation"
  cd "$curdir"
  exit 1
fi
