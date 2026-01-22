# Tmux Setup Guide

## Automatic Installation

The tmux setup is automated during the main installation process:

```bash
cd ~/hyprconfig
./install.sh
```

This will:
1. Install tmux package
2. Clone TPM (Tmux Plugin Manager)
3. Set up tmux configuration

## Manual Installation

If you need to set up tmux separately:

```bash
~/hyprconfig/install/tmux.sh
```

## Installing Tmux Plugins

After the installation script runs, you need to install the tmux plugins:

### Method 1: Interactive (Recommended)

1. Start tmux:
   ```bash
   tmux
   ```

2. Install plugins by pressing:
   ```
   Ctrl+A then Shift+I
   ```
   
   Detailed steps:
   - Hold `Ctrl` and press `A`
   - Release both keys
   - Hold `Shift` and press `I`

3. Wait for plugins to install (you'll see a progress bar)

4. Done! Plugins are now installed.

### Method 2: Command Line

Install all plugins from the command line:

```bash
~/.config/tmux/plugins/tpm/bin/install_plugins
```

## Configured Plugins

The following plugins are pre-configured:

| Plugin | Description |
|--------|-------------|
| **tmux-sensible** | Sensible default settings |
| **tmux-power** | Powerline-style theme (everforest) |
| **tmux-prefix-highlight** | Shows when prefix key is pressed |
| **tmux-resurrect** | Save and restore tmux sessions |
| **tmux-continuum** | Automatic session saving |
| **tmux-sessionist** | Session management utilities |
| **tmux-fzf** | Fuzzy finder integration |
| **tmux-yank** | Copy to system clipboard |

## Plugin Installation Location

Plugins are installed in:
```
~/.config/tmux/plugins/
├── tpm/                    ← Plugin manager
├── tmux-sensible/
├── tmux-power/
├── tmux-resurrect/
└── ... (other plugins)
```

## Tmux Configuration

Configuration file location:
```
~/.config/tmux/tmux.conf
```

Key customizations:
- **Prefix key**: `Ctrl+A` (instead of default `Ctrl+B`)
- **Mouse support**: Enabled
- **Vi mode**: Enabled for copy mode
- **256 color**: Enabled
- **Clipboard**: Integrated with system clipboard

## Common Tmux Commands

### Sessions
```bash
# Create new session
tmux new -s myproject

# List sessions
tmux ls

# Attach to session
tmux attach -t myproject

# Detach from session
Ctrl+A then D
```

### Windows (inside tmux)
```bash
Ctrl+A then N      # New window
Ctrl+A then C-l    # Next window
Ctrl+A then C-h    # Previous window
Ctrl+A then C-k    # Kill window
Ctrl+A then R      # Rename session
```

### Panes (inside tmux)
```bash
Ctrl+A then V      # Split vertically
Ctrl+A then H/J/K/L # Navigate panes
Ctrl+A then K      # Kill pane
```

### Plugin Management
```bash
Ctrl+A then Shift+I     # Install plugins
Ctrl+A then Shift+U     # Update plugins
Ctrl+A then Alt+U       # Uninstall plugins
```

## Updating Plugins

To update all plugins to the latest version:

1. Inside tmux, press:
   ```
   Ctrl+A then Shift+U
   ```

Or from command line:
```bash
~/.config/tmux/plugins/tpm/bin/update_plugins all
```

## Uninstalling Plugins

To remove plugins that are no longer in the config:

1. Remove the plugin line from `~/.config/tmux/tmux.conf`
2. Inside tmux, press:
   ```
   Ctrl+A then Alt+U
   ```

## Session Persistence (tmux-resurrect)

Save and restore your tmux environment:

### Save Session
```bash
Ctrl+A then Ctrl+S
```

### Restore Session
```bash
Ctrl+A then Ctrl+R
```

Sessions are automatically saved every 15 minutes with tmux-continuum.

## Troubleshooting

### Plugins Not Installing

**Check TPM is installed:**
```bash
ls ~/.config/tmux/plugins/tpm
```

**Manually clone TPM if missing:**
```bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

**Reload tmux config:**
```bash
# Inside tmux:
Ctrl+A then R
```

### Theme Not Loading

**Ensure plugins are installed:**
```bash
ls ~/.config/tmux/plugins/
```

Should show multiple plugin directories.

**Reload tmux:**
```bash
# Inside tmux:
tmux source ~/.config/tmux/tmux.conf
```

### Keybinding Not Working

**Check prefix key:**
The prefix is `Ctrl+A`, not the default `Ctrl+B`.

**Test prefix highlight:**
When you press `Ctrl+A`, you should see a visual indicator in the status bar.

## Resources

- [TPM Documentation](https://github.com/tmux-plugins/tpm)
- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════════════╗
║                    TMUX QUICK REFERENCE                       ║
╠═══════════════════════════════════════════════════════════════╣
║ PREFIX KEY: Ctrl+A (not Ctrl+B!)                              ║
╠═══════════════════════════════════════════════════════════════╣
║ PLUGINS                                                       ║
║   Ctrl+A Shift+I     Install plugins                          ║
║   Ctrl+A Shift+U     Update plugins                           ║
║   Ctrl+A Alt+U       Uninstall removed plugins                ║
╠═══════════════════════════════════════════════════════════════╣
║ SESSIONS                                                      ║
║   Ctrl+A C           Create new session                       ║
║   Ctrl+A D           Detach from session                      ║
║   Ctrl+A C-q         Kill session                             ║
║   Ctrl+A R           Rename session                           ║
╠═══════════════════════════════════════════════════════════════╣
║ WINDOWS                                                       ║
║   Ctrl+A N           New window                               ║
║   Ctrl+A C-l         Next window                              ║
║   Ctrl+A C-h         Previous window                          ║
║   Ctrl+A C-k         Kill window                              ║
╠═══════════════════════════════════════════════════════════════╣
║ PANES                                                         ║
║   Ctrl+A V           Split vertical                           ║
║   Ctrl+A H/J/K/L     Navigate panes (vim-like)                ║
║   Ctrl+A K           Kill pane                                ║
╠═══════════════════════════════════════════════════════════════╣
║ COPY MODE (VI)                                                ║
║   Ctrl+A [           Enter copy mode                          ║
║   V                  Begin selection                          ║
║   Y                  Copy selection                           ║
║   Ctrl+A ]           Paste                                    ║
╠═══════════════════════════════════════════════════════════════╣
║ SESSION PERSISTENCE                                           ║
║   Ctrl+A Ctrl+S      Save session                             ║
║   Ctrl+A Ctrl+R      Restore session                          ║
╚═══════════════════════════════════════════════════════════════╝
```

---

**Remember:** After installation, start tmux and press `Ctrl+A` then `Shift+I` to install all plugins!
