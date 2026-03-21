#!/usr/bin/env bash
set -euo pipefail

# message-log.sh — PostToolUse hook for mcp__plugin_telegram_telegram__reply
# Logs outbound Telegram messages to ~/.conductor/messages.jsonl
# Receives tool input/output on stdin as JSON

CONDUCTOR_DIR="$HOME/.conductor"
mkdir -p "$CONDUCTOR_DIR"

INPUT=$(cat)

# Extract fields from tool input
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null)
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)

if [[ -z "$TOOL_INPUT" ]]; then
  exit 0
fi

CHAT_ID=$(echo "$TOOL_INPUT" | jq -r '.chat_id // empty' 2>/dev/null)
TEXT=$(echo "$TOOL_INPUT" | jq -r '.text // empty' 2>/dev/null)
REPLY_TO=$(echo "$TOOL_INPUT" | jq -r '.reply_to // empty' 2>/dev/null)

# Extract message_id from tool output (format varies)
MSG_ID=$(echo "$TOOL_OUTPUT" | grep -oE '"message_id":\s*[0-9]+' | grep -oE '[0-9]+' || true)
if [[ -z "$MSG_ID" ]]; then
  MSG_ID=$(echo "$TOOL_OUTPUT" | grep -oE 'id: [0-9]+' | head -1 | grep -oE '[0-9]+' || true)
fi

# Default to 0 if we can't extract an ID
MSG_ID="${MSG_ID:-0}"

SLUG="${CONDUCTOR_SLUG:-orchestrator}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Build reply_to field
REPLY_TO_JSON="null"
if [[ -n "$REPLY_TO" && "$REPLY_TO" != "null" ]]; then
  REPLY_TO_JSON="$REPLY_TO"
fi

# Append to messages log
echo "{\"id\":${MSG_ID},\"from\":\"claude\",\"session\":\"${SLUG}\",\"text\":$(printf '%s' "$TEXT" | jq -Rs .),\"ts\":\"${TS}\",\"reply_to\":${REPLY_TO_JSON}}" >> "$CONDUCTOR_DIR/messages.jsonl"
