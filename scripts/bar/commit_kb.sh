#!/bin/bash
#

KB_DIR="/home/kostia/org-roam"

cd $KB_DIR

if git status | grep "nothing to commit" >/dev/null &>/dev/null; then
    exit 0
fi

git add -A;

git commit -m "AUTO KB UPDATE: $(date)"
git push origin HEAD
