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
   - `CR_CHAT_ID` — set by cr-spawn.sh via tmux set-environment
   - `CR_SLUG` — set by cr-spawn.sh via tmux set-environment

3. If environment variables are not available, read them from `~/.channel-routing/manifest.jsonl` using the current session context

4. Run the reply script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-reply.sh "<chat_id>" "<text>"
   ```

5. The script handles:
   - Reading the bot token from `~/.claude/channels/telegram/.env`
   - Sending via Telegram Bot API
   - Logging the sent message to `~/.channel-routing/messages.jsonl`

6. Report the sent message ID
