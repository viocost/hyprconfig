#!/bin/bash

# Tmux and TPM (Tmux Plugin Manager) setup script

echo "=========================================="
echo "  Tmux & Plugin Manager Setup"
echo "=========================================="
echo ""

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "❌ Error: tmux is not installed."
    echo "Please run the main installation script first."
    exit 1
fi

# Define paths
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
TMUX_CONF="$HOME/.config/tmux/tmux.conf"

# Clone TPM if not already installed
if [ -d "$TPM_DIR" ]; then
    echo "✓ TPM already installed at $TPM_DIR"
    echo "  Updating TPM..."
    cd "$TPM_DIR" && git pull origin master 2>/dev/null
else
    echo "📦 Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    
    if [ $? -eq 0 ]; then
        echo "✓ TPM installed successfully"
    else
        echo "❌ Failed to install TPM"
        exit 1
    fi
fi

# Check if tmux config exists
if [ ! -f "$TMUX_CONF" ]; then
    echo "⚠️  Warning: Tmux config not found at $TMUX_CONF"
    echo "   Make sure symlinks are created (run install/symlinks.sh)"
else
    echo "✓ Tmux config found at $TMUX_CONF"
fi

echo ""
echo "=========================================="
echo "  TPM Installation Complete!"
echo "=========================================="
echo ""
echo "📋 Configured Plugins:"
echo "  • tmux-sensible       - Sensible defaults"
echo "  • tmux-power          - Powerline theme"
echo "  • tmux-prefix-highlight - Show prefix key"
echo "  • tmux-resurrect      - Save/restore sessions"
echo "  • tmux-continuum      - Auto-save sessions"
echo "  • tmux-sessionist     - Session management"
echo "  • tmux-fzf            - Fuzzy finder integration"
echo "  • tmux-yank           - Copy to clipboard"
echo ""
echo "⚠️  IMPORTANT: To install plugins, you need to:"
echo ""
echo "  1. Start tmux:"
echo "     tmux"
echo ""
echo "  2. Press the plugin install keybind:"
echo "     Ctrl+A then Shift+I"
echo "     (Hold Ctrl, press A, release both, then hold Shift and press I)"
echo ""
echo "  3. Wait for plugins to install (you'll see a progress bar)"
echo ""
echo "  4. Done! Plugins will be installed in:"
echo "     ~/.config/tmux/plugins/"
echo ""
echo "Alternatively, install plugins from command line:"
echo "  ~/.config/tmux/plugins/tpm/bin/install_plugins"
echo ""
