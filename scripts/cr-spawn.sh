#!/usr/bin/env bash
set -euo pipefail

# cr-spawn.sh — Create a new child Claude Code session in tmux
# Usage: cr-spawn.sh <slug> <cwd> <chat_id> <description> <initial_prompt>

SLUG="${1:?Usage: cr-spawn.sh <slug> <cwd> <chat_id> <description> <initial_prompt>}"
CWD="${2:?Missing cwd}"
CHAT_ID="${3:?Missing chat_id}"
DESC="${4:-}"
INITIAL_PROMPT="${5:-}"

CR_DIR="$HOME/.channel-routing"
TMUX_SESSION="cr-${SLUG}"
CLAUDE_SESSION_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Resolve plugin root (parent of scripts/)
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure state directories exist
mkdir -p "$CR_DIR/sessions/${CLAUDE_SESSION_ID}/hooks"

# Generate child session settings.json with SessionEnd hook
cat > "$CR_DIR/sessions/${CLAUDE_SESSION_ID}/hooks/settings.json" <<SETTINGS
{
  "hooks": {
    "SessionEnd": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash $CR_DIR/sessions/${CLAUDE_SESSION_ID}/hooks/on-stop.sh"
      }]
    }]
  },
  "permissions": {
    "deny": ["Read($HOME/.channel-routing/**)", "Read($HOME/.claude/channels/**)"]
  }
}
SETTINGS

# Generate on-stop.sh for this session
cat > "$CR_DIR/sessions/${CLAUDE_SESSION_ID}/hooks/on-stop.sh" <<ONSTOP
#!/usr/bin/env bash
set -euo pipefail
SLUG="${SLUG}"
TS=\$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
echo "{\"event\":\"suspend\",\"slug\":\"\$SLUG\",\"reason\":\"claude_exit\",\"ts\":\"\$TS\"}" >> "$CR_DIR/manifest.jsonl"
ONSTOP
chmod +x "$CR_DIR/sessions/${CLAUDE_SESSION_ID}/hooks/on-stop.sh"

# Create tmux session
tmux new-session -d -s "$TMUX_SESSION" -c "$CWD" -x 220 -y 50

# Set environment variables via tmux (not in scrollback)
tmux set-environment -t "$TMUX_SESSION" CR_SLUG "$SLUG"
tmux set-environment -t "$TMUX_SESSION" CR_CHAT_ID "$CHAT_ID"

# Capture OAuth from macOS keychain (fallback to env)
OAUTH_TOKEN="${CLAUDE_OAUTH_TOKEN:-}"
if [[ -z "$OAUTH_TOKEN" ]]; then
  OAUTH_TOKEN=$(security find-generic-password -s "claude-oauth" -w 2>/dev/null || true)
fi
if [[ -n "$OAUTH_TOKEN" ]]; then
  tmux set-environment -t "$TMUX_SESSION" CLAUDE_OAUTH_TOKEN "$OAUTH_TOKEN"
fi

# Launch Claude interactively
tmux send-keys -t "${TMUX_SESSION}:0.0" \
  "claude --name ${SLUG} --session-id ${CLAUDE_SESSION_ID} --dangerously-skip-permissions --settings $CR_DIR/sessions/${CLAUDE_SESSION_ID}/hooks/settings.json --plugin-dir ${PLUGIN_ROOT}" Enter

# Wait for Claude to start
sleep 3

# Inject initial prompt if provided
if [[ -n "$INITIAL_PROMPT" ]]; then
  TMPFILE=$(mktemp)
  printf '%s' "$INITIAL_PROMPT" > "$TMPFILE"
  tmux load-buffer "$TMPFILE"
  tmux paste-buffer -t "${TMUX_SESSION}:0.0"
  tmux send-keys -t "${TMUX_SESSION}:0.0" Enter
  rm -f "$TMPFILE"
fi

# Append spawn event to manifest
echo "{\"event\":\"spawn\",\"slug\":\"${SLUG}\",\"desc\":$(printf '%s' "$DESC" | jq -Rs .),\"cwd\":\"${CWD}\",\"tmux\":\"${TMUX_SESSION}\",\"claude_session_id\":\"${CLAUDE_SESSION_ID}\",\"status\":\"running\",\"chat_id\":\"${CHAT_ID}\",\"ts\":\"${TS}\"}" >> "$CR_DIR/manifest.jsonl"

echo "Spawned session '${SLUG}' in tmux '${TMUX_SESSION}' (claude session: ${CLAUDE_SESSION_ID})"
