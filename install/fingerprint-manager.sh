#!/bin/bash

# Fingerprint management utility for Hyprland
# Provides easy commands for managing fingerprint authentication

SCRIPT_NAME="$(basename "$0")"

function show_help() {
    cat << EOF
Fingerprint Management Utility for Hyprland

USAGE:
    $SCRIPT_NAME [COMMAND]

COMMANDS:
    enroll [finger]      Enroll a new fingerprint
                         Example: $SCRIPT_NAME enroll right-index-finger
                         
    list                 List all enrolled fingerprints
    
    delete [finger]      Delete a specific fingerprint
                         Example: $SCRIPT_NAME delete right-thumb
                         
    delete-all           Delete all fingerprints
    
    test                 Test fingerprint authentication
    
    status               Show fprintd service status
    
    restart              Restart fprintd service
    
    help                 Show this help message

AVAILABLE FINGERS:
    left-thumb, left-index-finger, left-middle-finger, 
    left-ring-finger, left-little-finger
    right-thumb, right-index-finger, right-middle-finger,
    right-ring-finger, right-little-finger

EXAMPLES:
    # Enroll your right index finger
    $SCRIPT_NAME enroll right-index-finger
    
    # List enrolled fingerprints
    $SCRIPT_NAME list
    
    # Delete a specific finger
    $SCRIPT_NAME delete right-thumb
    
    # Test authentication
    $SCRIPT_NAME test

EOF
}

function check_fprintd() {
    if ! command -v fprintd-enroll &> /dev/null; then
        echo "❌ Error: fprintd is not installed."
        echo "Please install it first:"
        echo "  sudo pacman -S fprintd"
        exit 1
    fi
    
    if ! systemctl is-active --quiet fprintd.service; then
        echo "⚠️  Warning: fprintd service is not running."
        echo "Starting service..."
        sudo systemctl start fprintd.service
    fi
}

function enroll_fingerprint() {
    check_fprintd
    
    local finger="$1"
    
    if [ -z "$finger" ]; then
        echo "Error: Please specify a finger name."
        echo ""
        echo "Available fingers:"
        echo "  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger"
        echo "  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger"
        echo ""
        echo "Example: $SCRIPT_NAME enroll right-index-finger"
        exit 1
    fi
    
    echo "Enrolling $finger for user $USER..."
    echo "Follow the prompts and scan your finger multiple times."
    echo ""
    
    fprintd-enroll -f "$finger" "$USER"
}

function list_fingerprints() {
    check_fprintd
    echo "Enrolled fingerprints for $USER:"
    fprintd-list "$USER" || echo "No fingerprints enrolled."
}

function delete_fingerprint() {
    check_fprintd
    
    local finger="$1"
    
    if [ -z "$finger" ]; then
        echo "Error: Please specify a finger name."
        echo "Example: $SCRIPT_NAME delete right-index-finger"
        exit 1
    fi
    
    echo "Deleting $finger for user $USER..."
    fprintd-delete "$USER" -f "$finger"
}

function delete_all_fingerprints() {
    check_fprintd
    
    read -p "Are you sure you want to delete ALL fingerprints? (y/N): " confirm
    if [[ "${confirm,,}" =~ ^y(es)?$ ]]; then
        echo "Deleting all fingerprints for user $USER..."
        fprintd-delete "$USER"
    else
        echo "Cancelled."
    fi
}

function test_fingerprint() {
    check_fprintd
    
    echo "Testing fingerprint authentication..."
    echo "Please scan your enrolled finger."
    echo ""
    
    if fprintd-verify; then
        echo "✓ Authentication successful!"
    else
        echo "✗ Authentication failed."
    fi
}

function show_status() {
    check_fprintd
    
    echo "=== fprintd Service Status ==="
    systemctl status fprintd.service --no-pager
    echo ""
    echo "=== Enrolled Fingerprints ==="
    list_fingerprints
}

function restart_service() {
    echo "Restarting fprintd service..."
    sudo systemctl restart fprintd.service
    echo "✓ Service restarted."
}

# Main command dispatcher
case "${1:-help}" in
    enroll)
        enroll_fingerprint "$2"
        ;;
    list)
        list_fingerprints
        ;;
    delete)
        delete_fingerprint "$2"
        ;;
    delete-all)
        delete_all_fingerprints
        ;;
    test)
        test_fingerprint
        ;;
    status)
        show_status
        ;;
    restart)
        restart_service
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
