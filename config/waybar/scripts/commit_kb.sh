#!/bin/bash

KB_DIR="/home/kostia/org-roam"

cd "$KB_DIR" || exit 1

if git status | grep -q "nothing to commit"; then
    notify-send "KB Sync" "Nothing to commit" -u low
    exit 0
fi

git add -A
git commit -m "AUTO KB UPDATE: $(date)"
git push origin HEAD

if [ $? -eq 0 ]; then
    notify-send "KB Sync" "Successfully synced knowledge base" -u normal
else
    notify-send "KB Sync" "Failed to sync knowledge base" -u critical
fi
