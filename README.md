# hyprconfig

Clean, organized dotfiles for Hyprland on Arch Linux.

## Quick Start

```bash
git clone <your-repo-url> ~/hyprconfig
cd ~/hyprconfig
./install.sh
```

## Post-Installation Steps

### 1. Tmux Plugin Installation

After running the installer, you need to install tmux plugins:

```bash
# Start tmux
tmux

# Install plugins by pressing:
# Ctrl+A then Shift+I
# (Hold Ctrl, press A, release both, then hold Shift and press I)

# Wait for plugins to install, then you're done!
```

Or install from command line:
```bash
~/.config/tmux/plugins/tpm/bin/install_plugins
```

### 2. Fingerprint Setup (if enabled)

If you enabled fingerprint authentication during install:

```bash
# Enroll your fingerprint
~/hyprconfig/install/fingerprint-manager.sh enroll right-index-finger

# List enrolled fingerprints
~/hyprconfig/install/fingerprint-manager.sh list

# Test authentication
~/hyprconfig/install/fingerprint-manager.sh test
```

### 3. Reboot

Reboot to apply all system changes:
```bash
sudo reboot
```

## Directory Structure

```
hyprconfig/
├── install.sh           # Main installation orchestrator
├── run.sh              # Helper script for retryable commands
│
├── install/            # Installation scripts
│   ├── software.sh     # Package installation (pacman/yay) with prompt_install
│   └── git.sh          # Git and SSH configuration
│
├── config/             # Configuration files
│   ├── hypr/          # Hyprland configs
│   ├── waybar/        # Status bar
│   ├── rofi/          # Application launcher
│   ├── kitty/         # Terminal emulator
│   └── fastfetch/     # System info
│
├── scripts/            # Runtime scripts
│   ├── hyprland/      # Hyprland-specific scripts
│   ├── system/        # System utilities
│   ├── bar/           # Status bar modules
│   └── cli/           # CLI tools
│
├── assets/             # Images, fonts, etc.
└── zsh/               # Shell configuration
```

## What Gets Installed

### Hyprland & Wayland
- hyprland - Wayland compositor
- waybar - Status bar
- rofi-wayland - Application launcher
- hyprpaper - Wallpaper manager
- swaync - Notification daemon
- hyprlock & hypridle - Screen lock and idle management

### Screen Sharing & Media
- xdg-desktop-portal (+ hyprland & gtk backends)
- pipewire (audio/video, includes pulse/alsa/jack support)
- wireplumber (session manager)
- obs-studio
- grim & slurp (screenshots)
- hyprshot (screenshot tool)

### Development Tools
- neovim, emacs
- neovide (Neovim GUI)
- kitty terminal
- docker, docker-compose
- github-cli
- tmux
- yazi (file manager)
- fzf (fuzzy finder)

### Applications
- chromium, firefox
- bitwarden
- remmina (remote desktop)
- thunar (file manager)

### System Utilities
- NetworkManager - Network management
- bluez & blueman - Bluetooth support
- reflector - Mirror list management
- cronie - Cron job scheduler
- htop - System monitor
- Archive support: unzip, unrar, p7zip
- Filesystem support: ntfs-3g, exfatprogs

### Themes & Appearance
- GTK3/GTK4 with Arc theme
- Qt5/Qt6 theming tools
- Breeze cursor theme
- Papirus icon theme

### Optional (Prompted During Install)
- NVIDIA drivers (nvidia, nvidia-utils, nvidia-settings)
- Fingerprint authentication (fprintd, imagemagick)
- Shell enhancements (zoxide, starship)

## Utilities

### prompt_install Function (in software.sh)
Generic function for conditional package installation with user prompt. Can handle multiple package managers in a single call.

**Signature:**
```bash
prompt_install "Question?" pacman package1 package2 yay package3 pip package4
```

**Usage Examples:**
```bash
# Single package manager
prompt_install "Are you using NVIDIA?" pacman nvidia nvidia-utils nvidia-settings

# Multiple package managers in one call
prompt_install "Install development tools?" pacman gcc make yay visual-studio-code-bin

# Python packages
prompt_install "Install ML libraries?" pip tensorflow pytorch numpy pandas

# Mix package managers
prompt_install "Setup Node.js environment?" pacman nodejs npm yay nvm
```

The function will:
1. Prompt the user with the question (y/N)
2. If yes, install packages using the specified package manager(s)
3. Reuse the existing `install` function for retry logic
4. Skip if user answers no

## Design Principles

1. **Clean separation** - Installation logic separate from configs
2. **Organized by purpose** - Scripts grouped logically
3. **No bloat** - Built from scratch, only what's needed
4. **Wayland-first** - No X11 dependencies

## TODO

- [x] Add fonts installation ✓
- [x] Create symlinks script ✓
- [x] Port essential runtime scripts ✓
- [x] Build Hyprland configs from scratch ✓
- [x] Create waybar configuration ✓
- [x] Set up services/cron jobs ✓
- [ ] Add custom wallpaper management
- [ ] Document custom keybindings
