#!/bin/bash

# Wrapper script for git pull with automatic account switching
# Usage: ./vpull.sh [git pull arguments]

echo "🔄 Switching to ryanatvisgo account..."
gh auth switch --user ryanatvisgo
gh auth setup-git

echo "📥 Pulling from GitHub..."
git pull "$@"
PULL_EXIT_CODE=$?

echo "🔄 Switching back to ryanatbookmarked account..."
gh auth switch --user ryanatbookmarked

if [ $PULL_EXIT_CODE -eq 0 ]; then
    echo "✅ Pull successful!"
else
    echo "❌ Pull failed with exit code $PULL_EXIT_CODE"
fi

exit $PULL_EXIT_CODE
