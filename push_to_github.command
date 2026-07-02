#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Wiring git up to use your gh credentials..."
gh auth setup-git

echo "Resetting any stale .git state..."
rm -rf .git

echo "Initializing git repo..."
git init -q
git branch -M main 2>/dev/null || true

echo "Committing..."
git add -A
git commit -q -m "Claude Session Tracker: macOS menu bar app for claude.ai usage limits" || echo "(nothing new to commit)"

git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/baygut/claude-session-tracker.git

echo "Pushing to https://github.com/baygut/claude-session-tracker ..."
git push -u origin main

echo ""
echo "Done! https://github.com/baygut/claude-session-tracker"
read -p "Press Return to close this window..."
