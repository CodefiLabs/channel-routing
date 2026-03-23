---
name: sessions
description: List all channel-routing sessions with their status
---

# /sessions — List All Sessions

Show all managed sessions with their current status.

## Steps

1. Run the status script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-status.sh
   ```

2. Display the formatted table showing: session slug, status (running/suspended), description, last activity timestamp

3. If in a Telegram channel session, also reply the session table on Telegram

4. Note any sessions that were reaped (running but tmux dead → marked suspended)
