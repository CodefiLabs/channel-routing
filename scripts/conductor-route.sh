#!/usr/bin/env bash
set -euo pipefail

# conductor-route.sh — Inject a message into a child tmux session
# Usage: conductor-route.sh <slug> <message>

SLUG="${1:?Usage: conductor-route.sh <slug> <message>}"
shift
MESSAGE="$*"

TMUX_SESSION="conductor-${SLUG}"

# Verify session exists
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  echo "ERROR: tmux session '$TMUX_SESSION' not found" >&2
  exit 1
fi

# Write message to temp file for safe injection (handles special chars, multiline)
TMPFILE=$(mktemp)
printf '%s' "$MESSAGE" > "$TMPFILE"

# Inject via load-buffer + paste-buffer (safe for all content)
tmux load-buffer "$TMPFILE"
tmux paste-buffer -t "${TMUX_SESSION}:0.0"
tmux send-keys -t "${TMUX_SESSION}:0.0" Enter

rm -f "$TMPFILE"

# Log route event
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
echo "{\"event\":\"route\",\"slug\":\"${SLUG}\",\"ts\":\"${TS}\"}" >> "$HOME/.conductor/manifest.jsonl"

echo "Routed message to '${SLUG}'"
