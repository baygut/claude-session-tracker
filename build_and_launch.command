#!/bin/bash
cd "$(dirname "$0")"
echo "Building Claude Session Tracker..."
./build.sh
if [ -d "ClaudeSessionTracker.app" ]; then
    echo "Launching app..."
    open "ClaudeSessionTracker.app"
else
    echo "Build failed — see errors above."
fi
echo ""
read -p "Press Return to close this window..."
