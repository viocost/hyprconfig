#!/bin/bash

KB_DIR="/home/kostia/org-roam"

if [ ! -d "$KB_DIR" ]; then
    echo '{"text": "KB: N/A", "tooltip": "KB directory not found", "class": "kb-error"}'
    exit 0
fi

cd "$KB_DIR" || exit 1

# Check git status
if git status 2>/dev/null | grep -q "nothing to commit"; then
    # Clean - synced
    cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#01c64d\">✅</span>", "tooltip": "Knowledge Base: Synced", "class": "kb-synced"}
EOF
else
    # Dirty - needs sync
    cat <<EOF
{"text": "<b>KB:</b> <span foreground=\"#e8db92\">✍</span>", "tooltip": "Knowledge Base: Uncommitted changes", "class": "kb-dirty"}
EOF
fi
