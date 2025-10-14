#!/bin/bash

# Wrapper script for git push with automatic account switching
# Usage: ./vpush.sh [git push arguments]

echo "🔄 Switching to ryanatvisgo account..."
gh auth switch --user ryanatvisgo
gh auth setup-git

echo "📤 Pushing to GitHub..."
git push "$@"
PUSH_EXIT_CODE=$?

echo "🔄 Switching back to ryanatbookmarked account..."
gh auth switch --user ryanatbookmarked

if [ $PUSH_EXIT_CODE -eq 0 ]; then
    echo "✅ Push successful!"
else
    echo "❌ Push failed with exit code $PUSH_EXIT_CODE"
fi

exit $PUSH_EXIT_CODE
