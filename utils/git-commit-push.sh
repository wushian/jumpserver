#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./utils/git-commit-push.sh            # auto-generate message via Claude
#   ./utils/git-commit-push.sh "message"  # use provided message
#   MSG="message" ./utils/git-commit-push.sh

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
[[ -z "$BRANCH" ]] && { echo "Not on a branch (detached HEAD). Aborted."; exit 1; }

# Stage everything
git status --short
git add -A

# Nothing to commit?
if git diff --cached --quiet; then
  echo "Nothing to commit."
  exit 0
fi

# Resolve message: arg → env var → auto-generate
MESSAGE="${1:-${MSG:-}}"

if [[ -z "$MESSAGE" ]]; then
  if command -v claude &>/dev/null; then
    echo "Generating commit message..."
    DIFF=$(git diff --cached | head -c 8000)  # cap to avoid token overflow
    MESSAGE=$(printf '%s\n\n%s' \
      "Generate a single git commit message in conventional commits format (feat/fix/chore/refactor/docs/perf/style/test). Output ONLY the commit message, one line, max 72 characters. No quotes, no explanation." \
      "$DIFF" \
      | claude -p - 2>/dev/null | head -n1 | tr -d '"')
    echo "Generated: $MESSAGE"
    read -rp "Use this message? [Y/n/edit] " CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
    case "$CONFIRM" in
      n)
        echo "Aborted."; exit 1 ;;
      e|edit)
        read -rp "Message: " MESSAGE
        [[ -z "$MESSAGE" ]] && { echo "Aborted."; exit 1; } ;;
    esac
  else
    read -rp "Commit message: " MESSAGE
    [[ -z "$MESSAGE" ]] && { echo "Aborted."; exit 1; }
  fi
fi

git commit -m "$MESSAGE"
git push origin "$BRANCH"

echo "Pushed to origin/$BRANCH."
