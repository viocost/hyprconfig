#!/bin/bash

# Fingerprint authentication setup script
# This script configures fprintd and PAM for fingerprint authentication

echo "=========================================="
echo "  Fingerprint Authentication Setup"
echo "=========================================="
echo ""

# Check if fprintd is installed
if ! command -v fprintd-enroll &> /dev/null; then
    echo "❌ Error: fprintd is not installed."
    echo "Please run the main installation script first."
    exit 1
fi

# Enable and start fprintd service
echo "📋 Enabling fprintd.service..."
sudo systemctl enable fprintd.service
sudo systemctl start fprintd.service

# Check if service started successfully
if ! systemctl is-active --quiet fprintd.service; then
    echo "⚠️  Warning: fprintd service failed to start."
    echo "This might be normal if no fingerprint sensor is detected."
    echo ""
fi

# List available devices
echo "🔍 Checking for fingerprint devices..."
fprintd-list "$USER" 2>/dev/null || echo "No fingerprints enrolled yet."
echo ""

# Configure PAM
echo "🔐 Configuring PAM for fingerprint authentication..."

# Backup original PAM configurations
PAM_SYSTEM_AUTH="/etc/pam.d/system-auth"
PAM_HYPRLOCK="/etc/pam.d/hyprlock"

if [ -f "$PAM_SYSTEM_AUTH" ] && [ ! -f "${PAM_SYSTEM_AUTH}.backup" ]; then
    sudo cp "$PAM_SYSTEM_AUTH" "${PAM_SYSTEM_AUTH}.backup"
    echo "✓ Backed up system-auth to ${PAM_SYSTEM_AUTH}.backup"
fi

# Add fprintd to system-auth if not already present
if ! grep -q "pam_fprintd.so" "$PAM_SYSTEM_AUTH"; then
    echo "Adding fprintd to system-auth..."
    # Insert after the first auth line (before unix auth)
    sudo sed -i '/^auth\s\+\[success=1 default=ignore\]/a auth       sufficient   pam_fprintd.so' "$PAM_SYSTEM_AUTH" 2>/dev/null || \
    sudo sed -i '/^auth\s\+required\s\+pam_unix.so/i auth       sufficient   pam_fprintd.so' "$PAM_SYSTEM_AUTH"
    echo "✓ Added fprintd to system-auth"
else
    echo "✓ fprintd already configured in system-auth"
fi

# Configure hyprlock PAM if it exists
if [ ! -f "$PAM_HYPRLOCK" ]; then
    echo "Creating hyprlock PAM configuration..."
    sudo tee "$PAM_HYPRLOCK" > /dev/null << 'EOF'
# PAM configuration for hyprlock with fingerprint support
auth       sufficient   pam_fprintd.so
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF
    echo "✓ Created hyprlock PAM configuration"
else
    if [ ! -f "${PAM_HYPRLOCK}.backup" ]; then
        sudo cp "$PAM_HYPRLOCK" "${PAM_HYPRLOCK}.backup"
        echo "✓ Backed up hyprlock PAM to ${PAM_HYPRLOCK}.backup"
    fi
    
    if ! grep -q "pam_fprintd.so" "$PAM_HYPRLOCK"; then
        echo "Adding fprintd to hyprlock PAM..."
        sudo sed -i '1i auth       sufficient   pam_fprintd.so' "$PAM_HYPRLOCK"
        echo "✓ Added fprintd to hyprlock PAM"
    else
        echo "✓ fprintd already configured in hyprlock PAM"
    fi
fi

echo ""
echo "=========================================="
echo "  Fingerprint Enrollment"
echo "=========================================="
echo ""
echo "You can now enroll your fingerprints."
echo "For best results, enroll multiple fingers."
echo ""

# Function to enroll a finger
enroll_finger() {
    local finger="$1"
    echo "Enrolling $finger finger..."
    echo "Follow the prompts and scan your finger multiple times."
    echo ""
    
    if fprintd-enroll -f "$finger" "$USER"; then
        echo "✓ Successfully enrolled $finger finger"
        return 0
    else
        echo "⚠️  Failed to enroll $finger finger"
        return 1
    fi
}

# Prompt for finger enrollment
read -p "Would you like to enroll your fingerprints now? (Y/n): " answer
if [[ ! "${answer,,}" =~ ^n(o)?$ ]]; then
    echo ""
    echo "Available fingers:"
    echo "  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger"
    echo "  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger"
    echo ""
    
    # Enroll right index by default (most common)
    if enroll_finger "right-index-finger"; then
        echo ""
        read -p "Enroll another finger? (y/N): " more
        
        while [[ "${more,,}" =~ ^y(es)?$ ]]; do
            echo ""
            read -p "Enter finger name (e.g., right-thumb, left-index-finger): " finger_name
            if [ -n "$finger_name" ]; then
                enroll_finger "$finger_name"
            fi
            echo ""
            read -p "Enroll another finger? (y/N): " more
        done
    fi
else
    echo "Skipped enrollment. You can enroll later using:"
    echo "  fprintd-enroll -f <finger-name> \$USER"
    echo ""
fi

echo ""
echo "=========================================="
echo "  Configuration Complete!"
echo "=========================================="
echo ""
echo "Current enrolled fingerprints:"
fprintd-list "$USER" 2>/dev/null || echo "None"
echo ""
echo "To verify fingerprint authentication works:"
echo "  1. Lock your screen (Super+L)"
echo "  2. Try scanning your enrolled finger"
echo ""
echo "To enroll more fingerprints:"
echo "  fprintd-enroll -f right-thumb $USER"
echo ""
echo "To delete a fingerprint:"
echo "  fprintd-delete \$USER -f right-index-finger"
echo ""
echo "To delete all fingerprints:"
echo "  fprintd-delete \$USER"
echo ""
