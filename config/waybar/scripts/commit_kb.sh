#!/bin/bash

KB_DIR="/home/kostia/org-roam"
LOG_FILE="/tmp/kb_sync.log"

cd "$KB_DIR" || exit 1

# Function to log errors
log_error() {
    echo "$1" | tee -a "$LOG_FILE"
    notify-send "KB Sync Error" "$1" -u critical
}

# Check if there are uncommitted changes
if git status | grep -q "nothing to commit"; then
    notify-send "KB Sync" "Nothing to commit" -u low
    exit 0
fi

# Pull latest changes first
echo "Pulling latest changes..." > "$LOG_FILE"
if ! git pull origin HEAD >> "$LOG_FILE" 2>&1; then
    # Check if it's a conflict
    if git status | grep -q "rebase in progress\|Unmerged paths"; then
        log_error "Merge conflict detected! Manual resolution required."
        exit 1
    else
        log_error "Failed to pull changes from remote"
        exit 1
    fi
fi

# Stage all changes
git add -A

# Commit changes
if ! git commit -m "AUTO KB UPDATE: $(date)" >> "$LOG_FILE" 2>&1; then
    log_error "Failed to commit changes"
    exit 1
fi

# Push to remote
if ! git push origin HEAD >> "$LOG_FILE" 2>&1; then
    log_error "Failed to push changes to remote"
    exit 1
fi

notify-send "KB Sync" "Successfully synced knowledge base" -u normal
echo "Sync completed successfully" >> "$LOG_FILE"
