---
name: resume
description: Resume a suspended child Claude Code session
---

# /resume — Resume Suspended Session

Resume a previously suspended child session using `claude --resume`.

**Arguments**: `<slug>`

## Steps

1. Parse the slug argument (required)

2. Determine the chat_id:
   - From current channel session context if available
   - Or from the original spawn event in `~/.channel-routing/manifest.jsonl`

3. Run the resume script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-resume.sh "<slug>" "<chat_id>"
   ```

4. Report: session resumed, tmux session name, claude session ID
