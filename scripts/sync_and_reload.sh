#!/bin/bash

# Sentinel1 GitHub Sync & Reload Service
# This script monitors the remote git repository and triggers a hot reload
# on a running flutter process when changes are detected.

PROJECT_DIR="/Users/jamesmasebe/Desktop/Sentinel1"
FIFO_PATH="/tmp/flutter_sync_fifo"
INTERVAL=30

cd "$PROJECT_DIR"

# Create FIFO if it doesn't exist
[ -e "$FIFO_PATH" ] || mkfifo "$FIFO_PATH"

echo "Starting Sentinel1 Sync Service..."
echo "Monitoring branch: $(git branch --show-current)"

while true; do
    # Fetch latest from remote
    git fetch origin $(git branch --show-current) &>/dev/null
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Changes detected on GitHub. Pulling..."
        git pull origin $(git branch --show-current)
        
        echo "Triggering Hot Reload..."
        echo "r" > "$FIFO_PATH"
    fi
    
    sleep $INTERVAL
done
