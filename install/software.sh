#!/bin/bash

# First arg is pacman or yay, second - name of the package
function install() {
  if [[ $1 == pacman ]]; then
    COMMAND="sudo $1 -S $2 --noconfirm"

  elif [[ $1 == pip ]]; then
    COMMAND="$1 install $2 "
  elif [[ $1 == yay ]]; then
    COMMAND="$1 -S $2 --noconfirm"
  fi
  $COMMAND
  while [ $? -ne 0 ]; do
    read -p "Error installing $1. Try again? Y/n: " yn

    case $yn in
    [Yy]*) $COMMAND ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac

  done
}

function makedir() {
  # Add scripts
  if [[ ! -d $1 ]]; then
    mkdir -p $1
  fi
}

# Prompt user and conditionally install packages
# Usage: prompt_install "Question?" pacman package1 package2 yay package3 package4
# Example: prompt_install "Are you using NVIDIA?" pacman nvidia nvidia-utils
function prompt_install() {
  local question="$1"
  shift

  read -p "$question (y/N): " answer

  if [[ "${answer,,}" =~ ^y(es)?$ ]]; then
    local current_pm=""

    # Parse arguments: package_manager followed by packages until next package manager
    while [ $# -gt 0 ]; do
      case $1 in
      pacman | yay | pip | npm)
        current_pm="$1"
        shift
        ;;
      *)
        if [ -n "$current_pm" ]; then
          install "$current_pm" "$1"
        fi
        shift
        ;;
      esac
    done

    echo "Installation complete!"
  else
    echo "Skipping..."
  fi
}

pacman=(
  # Hyprland and Wayland essentials
  hyprland
  hyprlock
  hypridle
  hyprpaper
  socat
  waybar
  greetd
  greetd-tuigreet
  rofi-wayland
  gvfs
  gvfs-mtp
  networkmanager
  network-manager-applet

  # Screen sharing / portals (for Google Meet, OBS, etc.)
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xdg-utils
  pipewire
  pipewire-audio
  pipewire-pulse
  pipewire-alsa
  pipewire-jack
  wireplumber
  kvantum
  qt5ct
  qt6ct
  qt6-svg

  # Notification daemon
  swaync

  # Themes and appearance
  gtk3               # GTK3 toolkit
  gtk4               # GTK4 toolkit
  papirus-icon-theme # Icon theme

  # Bluetooth
  bluez       # Bluetooth protocol stack
  bluez-utils # Bluetooth utilities

  # Apps
  neovim
  openvpn
  docker
  docker-compose
  remmina
  emacs-wayland
  chromium
  firefox
  kitty
  tmux
  bitwarden
  obs-studio
  minikube
  qbittorrent
  github-cli
  yazi      # terminal file manager
  fastfetch # Shows sysinfo in terminal

  # Screenshot tool for Wayland
  grim
  slurp
  swappy # Screenshot editor (Wayland native)

  # Utils
  cronie
  brightnessctl
  rust
  npm
  curl
  sqlite
  python-pip
  python-urllib3
  hunspell-en_us
  sysstat
  acpi
  inxi
  yad
  gnome-system-monitor
  loupe
  nwg-look
  lsof
  direnv
  zsh
  blueman
  wl-clipboard # Wayland clipboard utility
  pavucontrol
  pamixer
  playerctl
  thunar
  thunar-volman
  tumbler
  thunar-archive-plugin
  htop
  fzf
  reflector
  unzip      # ZIP archive support
  unrar      # RAR archive support
  p7zip      # 7z archive support
  ntfs-3g    # NTFS filesystem support
  exfatprogs # exFAT filesystem support
  jq

  # Font manager
  gucharmap

  # For neovim
  tree-sitter
  tree-sitter-cli
  python-pynvim
  nodejs

  # LaTeX
  texlive-bin
  texlive-latexextra

  # Wireless tools
  iw
  wireless_tools
)

# Install stuff
for i in "${pacman[@]}"; do
  install pacman $i
done

# ============================================
# Install YAY AUR Helper if not present
# ============================================
if ! command -v yay &>/dev/null; then
  echo ""
  echo "📦 Installing YAY AUR helper..."

  # Ensure base-devel and git are installed
  sudo pacman -S --needed --noconfirm git base-devel

  # Clone and install yay
  TEMP_YAY_DIR="/tmp/yay-install-$$"
  git clone https://aur.archlinux.org/yay.git "$TEMP_YAY_DIR"
  cd "$TEMP_YAY_DIR"
  makepkg -si --noconfirm
  cd -
  rm -rf "$TEMP_YAY_DIR"

  if command -v yay &>/dev/null; then
    echo "✓ YAY installed successfully"
  else
    echo "❌ Failed to install YAY. Some AUR packages may not install."
    read -p "Continue anyway? (y/N): " answer
    if [[ ! "${answer,,}" =~ ^y(es)?$ ]]; then
      exit 1
    fi
  fi
else
  echo "✓ YAY is already installed"
fi

echo ""

yay=(
  # Steganography
  steghide
  wlogout
  pcloud-drive
  devour
  pinta
  hyprpolkitagent
  slack-desktop
  drawio-desktop
  wdisplays
  hyprshot
  hyprland-autoname-workspaces-git
  neovide # Neovim GUI client
)

# Install stuff from yay
for i in "${yay[@]}"; do
  install yay $i
done

# Conditional installations
echo ""
echo "=== Optional Hardware-Specific Packages ==="

# NVIDIA drivers (conditional)
prompt_install "Are you using NVIDIA graphics?" pacman nvidia nvidia-utils nvidia-settings

# Fingerprint authentication (conditional)
prompt_install "Enable fingerprint authentication for screen unlock?" pacman fprintd imagemagick

# Shell enhancements (optional)
prompt_install "Install zoxide (smart cd) and starship (prompt)?" pacman zoxide starship

echo ""

function docker_permissions() {
  sudo usermod -aG docker $USER
}

PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'

function antigen() {
  makedir ~/.config/zsh
  curl -L git.io/antigen >~/.config/zsh/antigen.zsh

}

echo installing antigen
antigen

echo installing docker permissions
docker_permissions

echo setting up ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

chsh -s $(which zsh)
