#!/bin/bash

KB_DIR="/home/kostia/org-roam"
LOG_FILE="/tmp/kb_sync.log"

if [ ! -d "$KB_DIR" ]; then
    cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#eba0ac\">N/A</span>", "tooltip": "KB directory not found", "class": "kb-error"}
EOF
    exit 0
fi

cd "$KB_DIR" || exit 1

# Check for rebase/merge conflicts
if git status 2>/dev/null | grep -q "rebase in progress\|Unmerged paths"; then
    TOOLTIP="Knowledge Base: MERGE CONFLICT! Manual resolution required."
    if [ -f "$LOG_FILE" ]; then
        TOOLTIP="$TOOLTIP\n\nLog:\n$(tail -5 $LOG_FILE)"
    fi
    cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#eba0ac\">⚠️</span>", "tooltip": "$TOOLTIP", "class": "kb-error"}
EOF
    exit 0
fi

# Check if last sync failed
if [ -f "$LOG_FILE" ]; then
    if grep -q "Failed\|error\|Error" "$LOG_FILE"; then
        LAST_ERROR=$(grep -i "failed\|error" "$LOG_FILE" | tail -1)
        cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#e8db92\">⚠️</span>", "tooltip": "Last sync failed: $LAST_ERROR", "class": "kb-dirty"}
EOF
        exit 0
    fi
fi

# Check git status
if git status 2>/dev/null | grep -q "nothing to commit"; then
    # Check if we're behind remote
    git fetch origin 2>/dev/null
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    
    if [ "$LOCAL" != "$REMOTE" ] && [ -n "$REMOTE" ]; then
        cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#89b4fa\">⬇️</span>", "tooltip": "Knowledge Base: Behind remote (pull needed)", "class": "kb-behind"}
EOF
    else
        cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#01c64d\">✅</span>", "tooltip": "Knowledge Base: Synced", "class": "kb-synced"}
EOF
    fi
else
    # Dirty - needs sync
    cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#e8db92\">✍</span>", "tooltip": "Knowledge Base: Uncommitted changes", "class": "kb-dirty"}
EOF
fi
