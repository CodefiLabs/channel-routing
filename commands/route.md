---
name: route
description: Send a message to a child Claude Code session
---

# /route — Route Message to Child Session

Inject a message into an existing child session's tmux pane.

**Arguments**: `<slug> <message>`

## Steps

1. Parse arguments:
   - `slug` (required): the session identifier to route to
   - `message` (required): the message text to inject

2. Check if the session is suspended by reading `~/.channel-routing/manifest.jsonl`:
   - Find the last event for this slug
   - If suspended, auto-resume it first using `bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-resume.sh "<slug>" "<chat_id>"`
   - Wait 3 seconds for Claude to start

3. Route the message:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-route.sh "<slug>" "<message>"
   ```

4. Spawn background verification:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-verify.sh "<slug>" "<chat_id>" &
   ```

5. Report: message routed to session slug
