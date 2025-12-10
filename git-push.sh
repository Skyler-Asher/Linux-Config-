#!/bin/bash

cd ~/Linux-config || exit

# Check if there are changes
if [[ -n $(git status --porcelain) ]]; then
    git add .
    git commit -m "Auto-push on $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main
    echo "✔ Changes pushed successfully."
else
    echo "No changes to push."
fi

