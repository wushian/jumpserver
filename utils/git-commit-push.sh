#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./utils/git-commit-push.sh "your commit message"
#   ./utils/git-commit-push.sh          # prompts for message
#   MSG="your message" ./utils/git-commit-push.sh

# Resolve message: arg → env var → prompt
MESSAGE="${1:-${MSG:-}}"
if [[ -z "$MESSAGE" ]]; then
  read -rp "Commit message: " MESSAGE
  [[ -z "$MESSAGE" ]] && { echo "Aborted: empty message."; exit 1; }
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
[[ -z "$BRANCH" ]] && { echo "Not on a branch (detached HEAD). Aborted."; exit 1; }

# Show what will be committed
git status --short

# Stage everything (tracked + untracked)
git add -A

# Nothing to commit?
if git diff --cached --quiet; then
  echo "Nothing to commit."
  exit 0
fi

git commit -m "$MESSAGE"
git push origin "$BRANCH"

echo "Pushed to origin/$BRANCH."
