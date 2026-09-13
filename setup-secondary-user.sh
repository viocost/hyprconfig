#!/bin/bash

# Quick setup script for a secondary, isolated Linux user (e.g. a "work"
# account kept separate from your personal one).
# This is a convenience wrapper that can be run standalone, and re-run on a
# fresh install to recreate the same separation.
#
# What it does:
#   1. Creates the user (home dir locked to 700, optional sudo/wheel)
#   2. Optionally wires up a dedicated tty so the new user gets their own
#      Hyprland session you can switch to with Ctrl+Alt+F<n>, without
#      logging either session out.
#
# Must be run with sudo: sudo ./setup-secondary-user.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "❌ Run this with sudo: sudo ./setup-secondary-user.sh"
    exit 1
fi

echo "=========================================="
echo "  Secondary User Setup"
echo "=========================================="
echo ""

read -p "Username for the new account: " USERNAME
if [[ -z "$USERNAME" ]]; then
    echo "❌ Username can't be empty."
    exit 1
fi

if id "$USERNAME" &>/dev/null; then
    echo "⚠️  User '$USERNAME' already exists — skipping creation."
else
    read -p "Give '$USERNAME' sudo access (wheel group)? (y/N): " grant_sudo
    SHELL_BIN="$(command -v bash)"

    if [[ "${grant_sudo,,}" =~ ^y(es)?$ ]]; then
        useradd -m -s "$SHELL_BIN" -G wheel "$USERNAME"
        echo "✓ Created '$USERNAME' with sudo (password required, no NOPASSWD)"
    else
        useradd -m -s "$SHELL_BIN" "$USERNAME"
        echo "✓ Created '$USERNAME' without sudo"
    fi

    chmod 700 "/home/$USERNAME"
    echo ""
    echo "Set a password for '$USERNAME':"
    passwd "$USERNAME"
fi

echo ""
read -p "Set up a dedicated tty for '$USERNAME' to run its own Hyprland session? (y/N): " setup_tty
if [[ "${setup_tty,,}" =~ ^y(es)?$ ]]; then
    read -p "Which tty number (e.g. 2)? " TTY_NUM
    if [[ ! "$TTY_NUM" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid tty number, skipping tty setup."
    else
        systemctl enable --now "getty@tty${TTY_NUM}.service"
        echo "✓ Enabled login prompt on tty${TTY_NUM}"

        PROFILE="/home/$USERNAME/.bash_profile"
        MARKER="# Auto-start Hyprland on tty${TTY_NUM} login"
        if [[ -f "$PROFILE" ]] && grep -qF "$MARKER" "$PROFILE"; then
            echo "⚠️  Auto-start already configured in $PROFILE — skipping."
        else
            cat >> "$PROFILE" <<EOF

$MARKER
if [ -z "\${WAYLAND_DISPLAY:-}" ] && [ "\$(tty)" = "/dev/tty${TTY_NUM}" ]; then
    exec start-hyprland
fi
EOF
            echo "✓ '$USERNAME' will auto-start Hyprland when logging in on tty${TTY_NUM}"
        fi

        echo ""
        echo "Switch with Ctrl+Alt+F${TTY_NUM} (and back with Ctrl+Alt+F1),"
        echo "neither session gets logged out."
    fi
fi

echo ""
echo "✓ Done."
