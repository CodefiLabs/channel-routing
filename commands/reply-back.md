---
name: reply-back
description: Send a response back to Telegram from a child session
---

# /reply-back — Reply to Telegram

Child sessions use this command to send their responses back to the Telegram user. This is the primary way child sessions communicate results.

**Arguments**: `<text>`

## Steps

1. Parse the text argument (required) — the message to send to Telegram

2. Determine chat_id and slug from environment:
   - `CONDUCTOR_CHAT_ID` — set by conductor-spawn.sh via tmux set-environment
   - `CONDUCTOR_SLUG` — set by conductor-spawn.sh via tmux set-environment

3. If environment variables are not available, read them from `~/.conductor/manifest.jsonl` using the current session context

4. Run the reply script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/conductor-reply.sh "<chat_id>" "<text>"
   ```

5. The script handles:
   - Reading the bot token from `~/.claude/channels/telegram/.env`
   - Sending via Telegram Bot API
   - Logging the sent message to `~/.conductor/messages.jsonl`

6. Report the sent message ID
