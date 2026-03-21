#!/usr/bin/env bash
set -euo pipefail

# conductor-verify.sh — Delayed health check for a child session
# Usage: conductor-verify.sh <slug> <chat_id>
# Designed to be run in background: conductor-verify.sh slug chat_id &

SLUG="${1:?Usage: conductor-verify.sh <slug> <chat_id>}"
CHAT_ID="${2:?Missing chat_id}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMUX_SESSION="conductor-${SLUG}"

# Wait 30 seconds before checking
sleep 30

# Check if tmux session is alive
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  # Session died — alert via Telegram
  bash "$SCRIPT_DIR/conductor-reply.sh" "$CHAT_ID" \
    "⚠️ Session '${SLUG}' has died. Use /resume to restart it."
  exit 0
fi

# Capture last 5 lines of tmux pane output
PANE_OUTPUT=$(tmux capture-pane -t "${TMUX_SESSION}:0.0" -p -S -5 2>/dev/null || true)

# Check for error patterns
ERROR_PATTERNS="rate limit|Rate limit|429|error|Error|ERROR|crashed|panic|Traceback"
if echo "$PANE_OUTPUT" | grep -qiE "$ERROR_PATTERNS"; then
  # Trouble detected — alert
  bash "$SCRIPT_DIR/conductor-reply.sh" "$CHAT_ID" \
    "⚠️ Session '${SLUG}' may have issues. Check tmux session '${TMUX_SESSION}'."
  exit 0
fi

# Healthy — silent exit
