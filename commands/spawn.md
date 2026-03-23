---
name: spawn
description: Create a new child Claude Code session in tmux
---

# /spawn — Create Child Session

Create a new child Claude Code session running in a tmux window.

**Arguments**: `<slug> [--cwd <path>] [--desc "<description>"] [--prompt "<initial prompt>"]`

## Steps

1. Parse arguments:
   - `slug` (required): kebab-case session identifier
   - `--cwd <path>` (optional): working directory for the session
   - `--desc "<text>"` (optional): description of what this session is for
   - `--prompt "<text>"` (optional): initial prompt to send to Claude

2. If `--cwd` is not provided, try to infer it:
   - Check `~/.channel-routing/projects.json` for a matching project name
   - If not found, use the current working directory

3. Run the spawn script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-spawn.sh "<slug>" "<cwd>" "<chat_id>" "<desc>" "<initial_prompt>"
   ```
   - `chat_id` comes from the current channel session context (if available) or defaults to empty

4. Report the result: session slug, tmux session name, working directory
