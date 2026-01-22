#!/bin/bash

# Quick setup script for fingerprint authentication
# This is a convenience wrapper that can be run standalone

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  Quick Fingerprint Setup"
echo "=========================================="
echo ""

# Check if already installed
if ! command -v fprintd-enroll &> /dev/null; then
    echo "fprintd is not installed."
    echo ""
    read -p "Install fprintd now? (Y/n): " answer
    
    if [[ ! "${answer,,}" =~ ^n(o)?$ ]]; then
        echo "Installing fprintd..."
        sudo pacman -S --noconfirm fprintd imagemagick
        echo "✓ Installation complete"
        echo ""
    else
        echo "❌ Cannot continue without fprintd."
        exit 1
    fi
fi

# Run the full setup script
"$SCRIPT_DIR/install/fingerprint.sh"
