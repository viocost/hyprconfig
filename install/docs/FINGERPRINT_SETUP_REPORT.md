# Fingerprint Authentication Setup Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**System:** Hyprland on Arch Linux  
**Configuration:** hyprconfig

---

## Overview

This report documents the complete fingerprint authentication setup for Hyprland screen unlock (hyprlock). The implementation uses `fprintd` (fprint daemon) which supports a wide range of fingerprint sensors and integrates seamlessly with PAM (Pluggable Authentication Modules).

---

## Components Installed

### 1. Core Packages

| Package | Purpose | Installation Method |
|---------|---------|---------------------|
| `fprintd` | Fingerprint authentication daemon | pacman (optional prompt) |
| `imagemagick` | Image processing utilities (dependency) | pacman (optional prompt) |

**Installation Location:** `/home/kostia/hyprconfig/install/software.sh:172`

The installation is **optional** and prompts the user during setup:
```bash
prompt_install "Enable fingerprint authentication for screen unlock?" pacman fprintd imagemagick
```

### 2. Configuration Files

#### a. Hyprlock Configuration
**File:** `/home/kostia/hyprconfig/config/hypr/hyprlock.conf`

**Changes Made:**
- Enabled fingerprint authentication block (lines 18-27)
- Configured authentication messages:
  - Ready message: "(Scan fingerprint to unlock)"
  - Present message: "(Scanning...)"
  - Invalid message: "(Invalid fingerprint)"

**Configuration Block:**
```conf
auth {
    fingerprint {
        enabled = true
        ready_message = (Scan fingerprint to unlock)
        present_message = (Scanning...)
        invalid_message = (Invalid fingerprint)
    }
}
```

#### b. PAM Configuration

**Files Modified:**

1. **System-wide authentication:** `/etc/pam.d/system-auth`
   - Added: `auth sufficient pam_fprintd.so`
   - Positioned before password authentication for priority
   - Backup created: `/etc/pam.d/system-auth.backup`

2. **Hyprlock PAM:** `/etc/pam.d/hyprlock`
   - Created new PAM configuration specifically for hyprlock
   - Includes fprintd authentication with fallback to system-auth
   - Backup created: `/etc/pam.d/hyprlock.backup`

**PAM Stack Configuration:**
```pam
auth       sufficient   pam_fprintd.so
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
```

**Rationale:** Using `sufficient` means if fingerprint succeeds, authentication passes immediately. If it fails, the system falls back to password authentication.

---

## Scripts Created

### 1. Installation Script
**Location:** `/home/kostia/hyprconfig/install/fingerprint.sh`

**Purpose:** Automated setup and enrollment of fingerprints

**Features:**
- ✅ Checks for fprintd installation
- ✅ Enables and starts fprintd.service
- ✅ Configures PAM (system-auth and hyprlock)
- ✅ Creates automatic backups of PAM configs
- ✅ Interactive fingerprint enrollment
- ✅ Supports multiple finger enrollment
- ✅ Provides clear status messages and next steps

**Usage:**
```bash
cd /home/kostia/hyprconfig
./install/fingerprint.sh
```

**Integration:** Automatically called during main installation if fprintd is installed.

### 2. Fingerprint Manager Utility
**Location:** `/home/kostia/hyprconfig/install/fingerprint-manager.sh`

**Purpose:** Easy-to-use CLI tool for fingerprint management

**Commands:**

| Command | Description | Example |
|---------|-------------|---------|
| `enroll [finger]` | Enroll a new fingerprint | `./fingerprint-manager.sh enroll right-index-finger` |
| `list` | List all enrolled fingerprints | `./fingerprint-manager.sh list` |
| `delete [finger]` | Delete specific fingerprint | `./fingerprint-manager.sh delete right-thumb` |
| `delete-all` | Delete all fingerprints | `./fingerprint-manager.sh delete-all` |
| `test` | Test fingerprint authentication | `./fingerprint-manager.sh test` |
| `status` | Show service status | `./fingerprint-manager.sh status` |
| `restart` | Restart fprintd service | `./fingerprint-manager.sh restart` |
| `help` | Show help message | `./fingerprint-manager.sh help` |

**Supported Fingers:**
- Left hand: thumb, index, middle, ring, little
- Right hand: thumb, index, middle, ring, little

**Usage Example:**
```bash
# Enroll your right index finger
~/hyprconfig/install/fingerprint-manager.sh enroll right-index-finger

# Check enrolled fingerprints
~/hyprconfig/install/fingerprint-manager.sh list

# Test authentication
~/hyprconfig/install/fingerprint-manager.sh test
```

---

## System Services

### fprintd.service

**Service:** `org.freedesktop.Fprint.service`  
**Type:** D-Bus activated system service  
**Management:**
```bash
# Enable service (auto-start on boot)
sudo systemctl enable fprintd.service

# Start service
sudo systemctl start fprintd.service

# Check status
systemctl status fprintd.service

# Restart service
sudo systemctl restart fprintd.service
```

**Configuration:** The setup script automatically enables and starts this service during installation.

---

## Installation Flow

### During Initial System Setup

1. User runs: `./hyprconfig/install.sh`
2. Software installation prompts user:
   ```
   Enable fingerprint authentication for screen unlock? (y/N):
   ```
3. If YES:
   - Installs `fprintd` and `imagemagick`
   - Continues with rest of installation
4. After git setup, automatically runs `./install/fingerprint.sh`
5. Fingerprint setup script:
   - Enables fprintd.service
   - Configures PAM
   - Prompts for fingerprint enrollment
   - Allows enrolling multiple fingers

### Post-Installation

Users can manage fingerprints anytime using:
```bash
~/hyprconfig/install/fingerprint-manager.sh [command]
```

---

## Usage Instructions

### First-Time Setup

1. **Install the system:**
   ```bash
   cd ~/hyprconfig
   ./install.sh
   ```
   
2. **When prompted, answer YES to fingerprint authentication**

3. **Follow enrollment prompts:**
   - Default: Right index finger
   - Optional: Enroll additional fingers for redundancy

4. **Test the setup:**
   ```bash
   # Lock your screen
   Super + L
   
   # Try unlocking with fingerprint
   # Should see: "(Scan fingerprint to unlock)"
   ```

### Adding More Fingerprints

```bash
# Enroll another finger
~/hyprconfig/install/fingerprint-manager.sh enroll left-index-finger

# Verify enrollment
~/hyprconfig/install/fingerprint-manager.sh list
```

### Troubleshooting

**Issue:** Fingerprint sensor not detected
```bash
# Check if device is available
fprintd-list $USER

# Restart the service
~/hyprconfig/install/fingerprint-manager.sh restart

# Check service logs
journalctl -u fprintd.service -f
```

**Issue:** Authentication not working
```bash
# Test fingerprint authentication
~/hyprconfig/install/fingerprint-manager.sh test

# Re-enroll fingerprint
~/hyprconfig/install/fingerprint-manager.sh delete right-index-finger
~/hyprconfig/install/fingerprint-manager.sh enroll right-index-finger
```

**Issue:** Need to reset everything
```bash
# Delete all fingerprints
~/hyprconfig/install/fingerprint-manager.sh delete-all

# Re-run setup
~/hyprconfig/install/fingerprint.sh
```

---

## Security Considerations

### Authentication Priority

The PAM configuration uses a **dual-factor fallback** approach:

1. **First attempt:** Fingerprint (fast, convenient)
2. **Fallback:** Password (if fingerprint fails or unavailable)

This ensures:
- ✅ Quick unlock with fingerprint when available
- ✅ Always able to unlock with password as backup
- ✅ No lockout if fingerprint sensor fails
- ✅ Secure even if fingerprint database is compromised (password still works)

### Best Practices

1. **Enroll multiple fingers:**
   - Recommended: Index and middle finger of both hands
   - Prevents lockout if one finger is injured/dirty

2. **Use strong password:**
   - Fingerprint is for convenience, password is ultimate fallback
   - Keep password secure and memorable

3. **Regular testing:**
   - Test fingerprint unlock periodically
   - Ensure sensor stays clean and functional

4. **Backup access:**
   - Always maintain SSH access to machine
   - Keep TTY access available (Ctrl+Alt+F2)

---

## Technical Details

### Supported Hardware

fprintd supports a wide range of fingerprint sensors through libfprint, including:

- **Validity Sensors:** VFS495, VFS5011, VFS0050, etc.
- **Synaptics:** Prometheus, Metallica series
- **ELAN:** 0c42, 0c4b, 0c4c, etc.
- **Goodix:** 5288, 5291, 5296, etc.
- **AuthenTec:** AES1610, AES2501, AES2550, etc.
- **Upek:** TouchStrip, TouchChip series

**Check your device:**
```bash
lsusb | grep -i finger
```

### Architecture

```
┌─────────────────────────────────────────────────┐
│                  Hyprlock                        │
│         (Screen Lock Interface)                  │
└────────────────────┬────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────┐
│              PAM (pam_fprintd.so)                │
│         (Pluggable Auth Module)                  │
└────────────────────┬────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────┐
│               fprintd.service                    │
│         (D-Bus Fingerprint Daemon)               │
└────────────────────┬────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────┐
│                 libfprint                        │
│         (Fingerprint Device Library)             │
└────────────────────┬────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────┐
│           Fingerprint Hardware                   │
│              (USB Device)                        │
└─────────────────────────────────────────────────┘
```

### Data Storage

Fingerprint data is stored in:
```
/var/lib/fprint/
└── [username]/
    └── [device_name]/
        └── [finger_name].xyt
```

**Format:** Binary representation (not reversible to fingerprint image)  
**Security:** Accessible only by root and fprintd service  
**Privacy:** Raw fingerprint images are never stored

---

## Files Modified Summary

| File | Type | Action |
|------|------|--------|
| `/home/kostia/hyprconfig/install/software.sh` | Modified | Added fingerprint prompt (line 172) |
| `/home/kostia/hyprconfig/install/fingerprint.sh` | Created | Setup and enrollment script |
| `/home/kostia/hyprconfig/install/fingerprint-manager.sh` | Created | Management utility |
| `/home/kostia/hyprconfig/config/hypr/hyprlock.conf` | Modified | Enabled fingerprint auth |
| `/home/kostia/hyprconfig/install.sh` | Modified | Integrated fingerprint setup |
| `/etc/pam.d/system-auth` | Modified | Added fprintd module (during setup) |
| `/etc/pam.d/hyprlock` | Created | PAM config for hyprlock (during setup) |

**Backups Created:**
- `/etc/pam.d/system-auth.backup` (automatically during setup)
- `/etc/pam.d/hyprlock.backup` (if file existed)

---

## Quick Reference

### Common Commands

```bash
# Enroll fingerprint
fprintd-enroll -f right-index-finger $USER

# List enrolled fingerprints
fprintd-list $USER

# Delete specific fingerprint
fprintd-delete $USER -f right-index-finger

# Delete all fingerprints
fprintd-delete $USER

# Test authentication
fprintd-verify

# Using the manager utility (easier)
~/hyprconfig/install/fingerprint-manager.sh [command]
```

### Keybindings (Hyprland)

| Key Combo | Action |
|-----------|--------|
| `Super + L` | Lock screen (triggers hyprlock) |
| `Ctrl + Alt + X`, then `k` | Lock screen via exit menu |

### Testing Checklist

- [ ] fprintd service is running
- [ ] At least one fingerprint enrolled
- [ ] Lock screen shows fingerprint prompt
- [ ] Can unlock with fingerprint
- [ ] Can unlock with password (fallback)
- [ ] Multiple monitors work correctly

---

## Comparison with Alternatives

### Why fprintd?

| Feature | fprintd | libfprint direct | howdy (facial) |
|---------|---------|------------------|----------------|
| **PAM Integration** | ✅ Native | ⚠️ Manual | ✅ Available |
| **Hardware Support** | ✅ Wide | ✅ Wide | 🔴 Camera only |
| **Hyprlock Support** | ✅ Yes | ⚠️ Complex | 🔴 Limited |
| **Maintenance** | ✅ Active | ✅ Active | ⚠️ Community |
| **Security** | ✅ High | ✅ High | ⚠️ Spoofable |
| **Arch Package** | ✅ Official | 🔴 Library only | ⚠️ AUR |

**Verdict:** fprintd is the best choice for fingerprint authentication on Hyprland/Arch Linux.

---

## Future Enhancements

Potential improvements for consideration:

1. **Multi-factor authentication:**
   - Require both fingerprint AND password for sudo
   - Time-based authentication rules

2. **Advanced enrollment:**
   - Quality threshold configuration
   - Multiple prints per finger

3. **Integration improvements:**
   - Waybar module showing fingerprint status
   - Notification on authentication attempts
   - Lock screen animation during scan

4. **Management GUI:**
   - Graphical tool for fingerprint management
   - Visual feedback during enrollment
   - Fingerprint quality indicator

---

## Support & References

### Official Documentation

- **fprintd:** https://fprint.freedesktop.org/
- **libfprint:** https://fprint.freedesktop.org/supported-devices.html
- **Hyprlock:** https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/
- **PAM:** https://linux.die.net/man/8/pam

### Arch Linux Wiki

- **fprint:** https://wiki.archlinux.org/title/Fprint
- **PAM:** https://wiki.archlinux.org/title/PAM

### Community Support

- **Hyprland Discord:** https://discord.gg/hyprland
- **GitHub Issues:** https://github.com/[your-repo]/hyprconfig/issues

---

## Changelog

**Version 1.0.0** - 2024-01-22
- Initial implementation
- Added fprintd integration
- Created setup and management scripts
- Configured hyprlock authentication
- Implemented PAM configuration
- Added optional installation prompt

---

## License & Credits

**Configuration:** Part of hyprconfig project  
**Author:** kostia  
**License:** [Your License]

**Dependencies:**
- fprintd: GPLv2+
- libfprint: LGPLv2.1+
- Hyprland: BSD 3-Clause

---

**End of Report**

*For questions or issues, please refer to the troubleshooting section or create an issue on the project repository.*
