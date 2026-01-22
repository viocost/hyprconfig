# Installation Scripts

This directory contains all installation and setup scripts for the hyprconfig system.

## Structure

```
install/
├── software.sh ..................... Main package installer
├── git.sh .......................... Git and SSH configuration
├── fonts.sh ........................ Font installation
├── symlinks.sh ..................... Configuration symlink manager
├── tmux.sh ......................... Tmux and TPM setup
├── fingerprint.sh .................. Fingerprint authentication setup
├── fingerprint-manager.sh .......... Fingerprint management CLI tool
└── docs/ ........................... Documentation
    ├── FINGERPRINT_SETUP_REPORT.md . Complete fingerprint guide
    ├── FINGERPRINT_CHANGES.txt ..... Quick changes summary
    ├── FINGERPRINT_QUICKSTART.txt .. Quick start guide
    └── FILE_STRUCTURE.txt .......... File structure overview
```

## Installation Scripts

### software.sh
Installs all required packages including:
- Hyprland and Wayland essentials
- Applications (chromium, neovim, kitty, etc.)
- Development tools
- Optional packages (prompts user)

### git.sh
Configures Git user credentials and SSH keys.

### fonts.sh
Installs required fonts for the system.

### symlinks.sh
Creates symbolic links from hyprconfig/config to ~/.config

### tmux.sh
Sets up Tmux and TPM (Tmux Plugin Manager):
- Clones TPM repository
- Configures plugin directory
- Displays instructions for plugin installation

**Post-installation:**
After running this script, start tmux and press `Ctrl+A` then `Shift+I` to install plugins.

### fingerprint.sh
Sets up fingerprint authentication:
- Enables fprintd service
- Configures PAM
- Enrolls fingerprints interactively

### fingerprint-manager.sh
CLI utility for managing fingerprints after installation.

**Usage:**
```bash
./install/fingerprint-manager.sh [command]

Commands:
  enroll [finger]   - Enroll a new fingerprint
  list              - List enrolled fingerprints
  delete [finger]   - Delete a fingerprint
  delete-all        - Delete all fingerprints
  test              - Test fingerprint authentication
  status            - Show service status
  restart           - Restart fprintd service
  help              - Show help
```

## Documentation

All fingerprint-related documentation is in `install/docs/`:

- **FINGERPRINT_SETUP_REPORT.md** - Complete 3000+ word guide
- **FINGERPRINT_QUICKSTART.txt** - Quick start commands
- **FINGERPRINT_CHANGES.txt** - Summary of changes
- **FILE_STRUCTURE.txt** - File organization overview

## Usage

Run the main installation script from the hyprconfig root:

```bash
cd ~/hyprconfig
./install.sh
```

This will run all necessary installation scripts in order.

For fingerprint-only setup:
```bash
~/hyprconfig/setup-fingerprint.sh
```
