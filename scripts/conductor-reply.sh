#!/usr/bin/env bash
set -euo pipefail

# conductor-reply.sh — Send a message to Telegram via Bot API
# Usage: conductor-reply.sh <chat_id> <text> [reply_to_message_id]
# Also reads CONDUCTOR_CHAT_ID from env if chat_id is "-"

CHAT_ID="${1:?Usage: conductor-reply.sh <chat_id> <text> [reply_to_message_id]}"
TEXT="${2:?Missing text}"
REPLY_TO="${3:-}"

# Allow "-" to mean "use env var"
if [[ "$CHAT_ID" == "-" ]]; then
  CHAT_ID="${CONDUCTOR_CHAT_ID:?CONDUCTOR_CHAT_ID not set}"
fi

# Read bot token from official channel plugin's .env
ENV_FILE="$HOME/.claude/channels/telegram/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: Telegram .env not found at $ENV_FILE" >&2
  exit 1
fi

TELEGRAM_BOT_TOKEN=$(grep -E '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'")
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
  echo "ERROR: TELEGRAM_BOT_TOKEN not found in $ENV_FILE" >&2
  exit 1
fi

# Build request payload
PAYLOAD=$(jq -n \
  --arg chat_id "$CHAT_ID" \
  --arg text "$TEXT" \
  --arg parse_mode "Markdown" \
  '{chat_id: $chat_id, text: $text, parse_mode: $parse_mode}')

if [[ -n "$REPLY_TO" ]]; then
  PAYLOAD=$(echo "$PAYLOAD" | jq --arg reply_to "$REPLY_TO" '. + {reply_to_message_id: ($reply_to | tonumber)}')
fi

# Send message
RESPONSE=$(curl -s -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

# Extract message_id from response
OK=$(echo "$RESPONSE" | jq -r '.ok // false')
if [[ "$OK" != "true" ]]; then
  echo "ERROR: Telegram API error: $(echo "$RESPONSE" | jq -r '.description // "unknown"')" >&2
  exit 1
fi

MSG_ID=$(echo "$RESPONSE" | jq -r '.result.message_id')

# Log to messages.jsonl
CONDUCTOR_DIR="$HOME/.conductor"
mkdir -p "$CONDUCTOR_DIR"
SLUG="${CONDUCTOR_SLUG:-orchestrator}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

echo "{\"id\":${MSG_ID},\"from\":\"claude\",\"session\":\"${SLUG}\",\"text\":$(printf '%s' "$TEXT" | jq -Rs .),\"ts\":\"${TS}\",\"reply_to\":${REPLY_TO:-null}}" >> "$CONDUCTOR_DIR/messages.jsonl"

echo "$MSG_ID"
