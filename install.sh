#!/bin/bash

# Main installation script for hyprconfig
# Run this on a fresh Arch Linux system to set up Hyprland environment
# 
# Usage:
#   ./install.sh              - Run full installation
#   ./install.sh fonts git    - Run only fonts.sh and git.sh
#   ./install.sh symlinks     - Run only symlinks.sh

# Function to run a specific install script
run_install_script() {
  local script_name="$1"
  local script_path="./install/${script_name}.sh"
  
  if [[ -f "$script_path" ]]; then
    echo "Running ${script_name}..."
    ./run.sh "$script_path"
  else
    echo "⚠️  Warning: Install script not found: ${script_path}"
    return 1
  fi
}

# Function to run full installation
run_full_install() {
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

  # Setup tmux and TPM
  echo "🖥️  Setting up Tmux and Plugin Manager..."
  sleep 1
  ./run.sh ./install/tmux.sh

  echo "🖥️  Setting up fonts..."
  sleep 1
  ./run.sh ./install/fonts.sh

  echo "🔗 Linking the config"
  sleep 1
  ./run.sh ./install/symlinks.sh

  # Generate host-specific waybar config (CPU core count)
  echo "📊 Configuring waybar (CPU cores)..."
  sleep 1
  ./run.sh ./install/waybar.sh

  # Setup greeter
  echo "👋 Setting up greeter (greetd/tuigreet)..."
  sleep 1
  ./run.sh ./install/greeter.sh

  # Setup system services
  echo "⚙️  Enabling system services..."
  sleep 1
  ./run.sh ./install/services.sh

  # Setup cron jobs
  echo "⏰ Setting up cron jobs..."
  sleep 1
  ./run.sh ./install/cron.sh

  # Setup Doom Emacs (optional)
  echo ""
  read -p "📝 Would you like to set up Doom Emacs? (y/N) " emacs_answer
  if [[ "${emacs_answer,,}" =~ ^y(es)?$ ]]; then
    echo "📝 Setting up Doom Emacs..."
    sleep 1
    ./run.sh ./install/emacs.sh
  else
    echo "⏭️  Skipping Doom Emacs setup."
  fi

  echo ""
  echo "=========================================="
  echo "  Installation Complete!"
  echo "=========================================="
  echo ""
  echo "📋 Post-Installation Steps:"
  echo ""
  echo "1. 🎨 Tmux Plugins:"
  echo "   Start tmux and install plugins:"
  echo "     tmux"
  echo "     # Then press: Ctrl+A then Shift+I"
  echo ""
  echo "2. 🔐 Fingerprint (if installed):"
  if pacman -Qi fprintd &>/dev/null; then
    echo "   Enroll your fingerprints:"
    echo "     ~/hyprconfig/install/fingerprint-manager.sh enroll right-index-finger"
  fi
  echo ""
  if [[ "${emacs_answer,,}" =~ ^y(es)?$ ]]; then
    echo "3. 📝 Doom Emacs:"
    echo "   Run 'doom sync' if you make changes to your config"
    echo "   Run 'doom upgrade' periodically to update packages"
    echo ""
    echo "4. 🔄 Reboot to apply all changes"
  else
    echo "3. 🔄 Reboot to apply all changes"
  fi
  echo ""
  echo "=========================================="
  echo ""
  read -p "Installation completed. Reboot now? (y/N) " answer
  if [[ "${answer,,}" =~ ^y(es)?$ ]]; then
    sudo reboot now
  else
    echo "Reboot cancelled. Please reboot manually to complete setup."
  fi
}

# Main execution logic
if [[ $# -eq 0 ]]; then
  # No arguments - run full installation
  run_full_install
else
  # Arguments provided - run specific install scripts
  echo "=========================================="
  echo "  Running Specific Install Scripts"
  echo "=========================================="
  echo ""
  
  for script_name in "$@"; do
    run_install_script "$script_name"
  done
  
  echo ""
  echo "=========================================="
  echo "  Selected Scripts Complete!"
  echo "=========================================="
fi
