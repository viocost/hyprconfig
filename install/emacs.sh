#!/bin/bash

# Emacs/Doom Emacs Setup Script for hyprconfig
# Sets up Doom Emacs with personal configuration

echo "=========================================="
echo "  Doom Emacs Setup"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if emacs is installed
if ! command -v emacs &> /dev/null; then
  echo "⚠️  Warning: emacs-wayland is not installed"
  echo "   It should have been installed by software.sh"
  read -p "Continue anyway? (y/N): " answer
  if [[ ! "${answer,,}" =~ ^y(es)?$ ]]; then
    echo "Skipping Emacs setup..."
    exit 0
  fi
fi

# Check if SSH keys are set up (needed for private repos)
if [ ! -f ~/.ssh/dev_key ] && [ ! -f ~/.ssh/id_rsa ]; then
  echo "❌ Error: No SSH key found in ~/.ssh/"
  echo "   Please run git.sh first to set up SSH keys"
  echo ""
  read -p "Skip Emacs setup? (Y/n): " answer
  if [[ ! "${answer,,}" =~ ^n(o)?$ ]]; then
    echo "Skipping Emacs setup..."
    exit 0
  fi
fi

# Test SSH connection to GitHub
echo "Testing SSH connection to GitHub..."
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "⚠️  Warning: Cannot connect to GitHub via SSH"
  echo "   This may fail if SSH keys are not set up correctly"
  echo ""
  read -p "Continue anyway? (y/N): " answer
  if [[ ! "${answer,,}" =~ ^y(es)?$ ]]; then
    echo "Skipping Emacs setup..."
    exit 0
  fi
fi

# 1. Clone Doom Emacs
if [ -d ~/.config/emacs ]; then
  echo "⚠️  ~/.config/emacs already exists"
  read -p "Remove and reinstall Doom Emacs? (y/N): " answer
  if [[ "${answer,,}" =~ ^y(es)?$ ]]; then
    echo "Removing existing Doom Emacs..."
    rm -rf ~/.config/emacs
  else
    echo "Keeping existing Doom Emacs installation"
  fi
fi

if [ ! -d ~/.config/emacs ]; then
  echo "📦 Cloning Doom Emacs..."
  if git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.config/emacs; then
    echo "✓ Doom Emacs cloned successfully"
  else
    echo "❌ Failed to clone Doom Emacs"
    exit 1
  fi

  echo "📦 Initializing submodules (doom+ modules)..."
  if git -C ~/.config/emacs submodule update --init --recursive; then
    echo "✓ Submodules initialized successfully"
  else
    echo "❌ Failed to initialize submodules"
    exit 1
  fi
fi

# 2. Clone Knowledge Base (org-roam)
if [ ! -d ~/org-roam ]; then
  echo "📦 Cloning Knowledge Base (org-roam)..."
  if git clone git@gitlab.com:viocost/kb.git ~/org-roam; then
    echo "✓ Knowledge Base cloned successfully"
  else
    echo "⚠️  Failed to clone Knowledge Base from GitLab"
    echo "   Continuing without org-roam..."
  fi
else
  echo "✓ Knowledge Base (org-roam) already exists at ~/org-roam"
fi

# 3. Clone Doom Configuration
if [ ! -d ~/.config/doom ]; then
  echo "📦 Cloning Doom configuration..."
  if git clone git@github.com:viocost/emacs-doom ~/.config/doom; then
    echo "✓ Doom configuration cloned successfully"
  else
    echo "❌ Failed to clone Doom configuration from GitHub"
    exit 1
  fi
else
  echo "✓ Doom configuration already exists at ~/.config/doom"
fi

# 4. Run doom sync
echo ""
echo "🔄 Running Doom sync..."
echo "   This will install packages and configure Doom Emacs"
echo "   This may take several minutes..."
echo ""

cd ~/.config/emacs/bin

if ./doom sync; then
  echo "✓ Doom sync completed successfully"
else
  echo "⚠️  Doom sync encountered issues"
  echo "   You may need to run: ~/.config/emacs/bin/doom sync manually"
fi

cd "$REPO_ROOT"

echo ""
echo "=========================================="
echo "  Doom Emacs Setup Complete!"
echo "=========================================="
echo ""
echo "📋 What was installed:"
echo "  • Doom Emacs - ~/.config/emacs"
echo "  • Doom config - ~/.config/doom"
echo "  • Knowledge Base - ~/org-roam"
echo ""
echo "💡 Useful Commands:"
echo "  • Start Emacs:         emacs"
echo "  • Doom sync:           ~/.config/emacs/bin/doom sync"
echo "  • Doom upgrade:        ~/.config/emacs/bin/doom upgrade"
echo "  • Doom doctor:         ~/.config/emacs/bin/doom doctor"
echo ""
echo "📝 First Time Setup:"
echo "  Run: doom doctor"
echo "  This will check for missing dependencies"
echo ""
