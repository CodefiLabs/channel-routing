#!/usr/bin/env bash
set -euo pipefail

# cr-stop.sh — Graceful shutdown of a child session
# Usage: cr-stop.sh <slug>

SLUG="${1:?Usage: cr-stop.sh <slug>}"
TMUX_SESSION="cr-${SLUG}"

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  echo "Session '$SLUG' is not running (no tmux session '$TMUX_SESSION')"
  exit 0
fi

# Send /exit to Claude
tmux send-keys -t "${TMUX_SESSION}:0.0" "/exit" Enter

# Wait for graceful shutdown
sleep 2

# Kill if still alive
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  tmux kill-session -t "$TMUX_SESSION"
  echo "Force-killed tmux session '$TMUX_SESSION'"
fi

# Log suspend event
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
echo "{\"event\":\"suspend\",\"slug\":\"${SLUG}\",\"reason\":\"manual_stop\",\"ts\":\"${TS}\"}" >> "$HOME/.channel-routing/manifest.jsonl"

echo "Stopped session '${SLUG}'"
