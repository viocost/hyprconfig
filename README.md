# hyprconfig

Clean, organized dotfiles for Hyprland on Arch Linux.

## Quick Start

```bash
git clone <your-repo-url> ~/hyprconfig
cd ~/hyprconfig
./install.sh
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
- mako - Notification daemon

### Screen Sharing & Media
- xdg-desktop-portal (+ hyprland & gtk backends)
- pipewire & wireplumber
- obs-studio
- grim & slurp (screenshots)

### Development Tools
- neovim, emacs
- kitty terminal
- docker, docker-compose
- github-cli
- tmux
- yazi (file manager)

### Applications
- chromium
- bitwarden
- remmina (remote desktop)

### Optional (Prompted During Install)
- NVIDIA drivers (nvidia, nvidia-utils, nvidia-settings)

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

- [ ] Add fonts installation
- [ ] Create symlinks script
- [ ] Port essential runtime scripts
- [ ] Build Hyprland configs from scratch
- [ ] Create waybar configuration
- [ ] Set up services/cron jobs
