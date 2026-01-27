#!/bin/bash

# Greeter setup script for hyprconfig
# Configures greetd with tuigreet for Hyprland

echo "=========================================="
echo "  Greetd/Tuigreet Setup"
echo "=========================================="
echo ""

# Check if greetd is installed
if ! command -v greetd &>/dev/null; then
  echo "❌ Error: greetd is not installed."
  echo "Please run the main installation script first."
  exit 1
fi

# Check if tuigreet is installed
if ! command -v tuigreet &>/dev/null; then
  echo "❌ Error: tuigreet is not installed."
  echo "Please run the main installation script first."
  exit 1
fi

# Check if start-hyprland exists
if ! command -v start-hyprland &>/dev/null; then
  echo "⚠️  Warning: start-hyprland command not found in PATH"
  echo "   The greeter will be configured but may not launch Hyprland correctly"
  echo "   Make sure Hyprland is properly installed"
fi

echo "📝 Creating greetd configuration..."

# Create the config directory if it doesn't exist
if [[ ! -d /etc/greetd ]]; then
  echo "Creating /etc/greetd directory..."
  mkdir -p /etc/greetd
fi

# Backup existing config if it exists
if [[ -f /etc/greetd/config.toml ]]; then
  echo "Backing up existing config to /etc/greetd/config.toml.backup"
  cp /etc/greetd/config.toml /etc/greetd/config.toml.backup
fi

# Write the new configuration
echo "Writing configuration to /etc/greetd/config.toml..."
tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
# The VT to run the greeter on. Can be "next", "current" or a number
# designating the VT.
vt = 1

# The default session, also known as the greeter.
[default_session]

command = "tuigreet --remember --user-menu --cmd start-hyprland"

# The user to run the command as. The privileges this user must have depends
# on the greeter. A graphical greeter may for example require the user to be
# in the `video` group.
user = "greeter"
EOF

if [[ $? -eq 0 ]]; then
  echo "✓ Configuration written successfully"
else
  echo "❌ Failed to write configuration"
  exit 1
fi

echo ""
echo "🔧 Enabling greetd service..."
systemctl enable greetd.service

if [[ $? -eq 0 ]]; then
  echo "✓ greetd service enabled successfully"
else
  echo "❌ Failed to enable greetd service"
  exit 1
fi

echo ""
echo "=========================================="
echo "  Greetd Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Configuration Details:"
echo "  • Greeter: tuigreet"
echo "  • Session: start-hyprland"
echo "  • Features: --remember --user-menu"
echo "  • VT: 1"
echo ""
echo "⚠️  IMPORTANT:"
echo "  The greeter is now ENABLED but not started."
echo "  It will start automatically on next boot."
echo ""
echo "  To start it now:"
echo "    sudo systemctl start greetd.service"
echo ""
echo "  To check status:"
echo "    sudo systemctl status greetd.service"
echo ""
