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
  rofi-wayland

  # Screen sharing / portals (for Google Meet, OBS, etc.)
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  pipewire
  wireplumber

  # Notification daemon
  mako

  # Apps
  neovim
  chromium
  openvpn
  docker
  docker-compose
  remmina
  emacs
  kitty
  tmux
  bitwarden
  obs-studio
  minikube
  qbittorrent
  pinta
  github-cli
  yazi      # terminal file manager
  fastfetch # Shows sysinfo in terminal

  # Screenshot tool for Wayland
  grim
  slurp

  # Utils
  cronie
  brightnessctl
  rust
  npm
  curl
  sqlite
  python-pip
  hunspell-en_us
  sysstat
  acpi
  lsof
  direnv
  zsh
  blueman
  wl-clipboard # Wayland clipboard utility

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

yay=(
  # Steganography
  steghide
  wlogout
  pcloud-drive
  devour
  slack-desktop
  drawio-desktop
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
