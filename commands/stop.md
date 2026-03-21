---
name: stop
description: Gracefully stop a child Claude Code session
---

# /stop — Stop Child Session

Gracefully shut down a child session by sending /exit and then killing tmux if needed.

**Arguments**: `<slug>`

## Steps

1. Parse the slug argument (required)

2. Run the stop script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/conductor-stop.sh "<slug>"
   ```

3. Report: session stopped, status updated to suspended

4. Note: The session's claude_session_id is preserved in the manifest for future `/resume`
