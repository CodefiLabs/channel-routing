#!/usr/bin/env bash
set -euo pipefail

# cr-resume.sh — Resume a suspended child session
# Usage: cr-resume.sh <slug> <chat_id>

SLUG="${1:?Usage: cr-resume.sh <slug> <chat_id>}"
CHAT_ID="${2:?Missing chat_id}"

CR_DIR="$HOME/.channel-routing"
TMUX_SESSION="cr-${SLUG}"
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Find the claude_session_id from manifest (last spawn event for this slug)
CLAUDE_SESSION_ID=$(grep "\"slug\":\"${SLUG}\"" "$CR_DIR/manifest.jsonl" | grep '"event":"spawn"' | tail -1 | python3 -c "import json,sys; print(json.load(sys.stdin)['claude_session_id'])" 2>/dev/null || true)

if [[ -z "$CLAUDE_SESSION_ID" ]]; then
  echo "ERROR: No session ID found for slug '${SLUG}'" >&2
  exit 1
fi

# Find the cwd from the spawn event
CWD=$(grep "\"slug\":\"${SLUG}\"" "$CR_DIR/manifest.jsonl" | grep '"event":"spawn"' | tail -1 | python3 -c "import json,sys; print(json.load(sys.stdin)['cwd'])" 2>/dev/null || true)
CWD="${CWD:-$HOME}"

# Check if already running
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  echo "Session '$SLUG' is already running"
  exit 0
fi

SETTINGS_PATH="$CR_DIR/sessions/${CLAUDE_SESSION_ID}/hooks/settings.json"

# Create tmux session
tmux new-session -d -s "$TMUX_SESSION" -c "$CWD" -x 220 -y 50

# Set environment variables
tmux set-environment -t "$TMUX_SESSION" CR_SLUG "$SLUG"
tmux set-environment -t "$TMUX_SESSION" CR_CHAT_ID "$CHAT_ID"

# Capture OAuth
OAUTH_TOKEN="${CLAUDE_OAUTH_TOKEN:-}"
if [[ -z "$OAUTH_TOKEN" ]]; then
  OAUTH_TOKEN=$(security find-generic-password -s "claude-oauth" -w 2>/dev/null || true)
fi
if [[ -n "$OAUTH_TOKEN" ]]; then
  tmux set-environment -t "$TMUX_SESSION" CLAUDE_OAUTH_TOKEN "$OAUTH_TOKEN"
fi

# Launch Claude with --resume
tmux send-keys -t "${TMUX_SESSION}:0.0" \
  "claude --resume ${CLAUDE_SESSION_ID} --dangerously-skip-permissions --settings ${SETTINGS_PATH} --plugin-dir ${PLUGIN_ROOT}" Enter

# Log resume event
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
echo "{\"event\":\"resume\",\"slug\":\"${SLUG}\",\"ts\":\"${TS}\"}" >> "$CR_DIR/manifest.jsonl"

echo "Resumed session '${SLUG}' (claude session: ${CLAUDE_SESSION_ID})"
