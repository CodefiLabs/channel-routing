---
name: conductor
description: Toggle conductor orchestrator mode on/off or check status
---

# /conductor — Orchestrator Mode Toggle

Manage conductor mode for this session. Conductor mode enables AI-powered message routing from Telegram to multiple child Claude Code sessions.

**Arguments**: `on`, `off`, or `status` (default: `status`)

Parse the arguments provided after `/conductor`.

## `/conductor on`

1. Create the state directory if needed: `mkdir -p ~/.conductor`
2. Write the sentinel file `~/.conductor/active` with content: the current timestamp
3. Confirm activation to the user
4. If in a Telegram channel session, reply on Telegram: "Conductor mode active. I'll route your messages to sessions."

## `/conductor off`

1. Remove `~/.conductor/active` if it exists
2. Confirm deactivation to the user
3. If in a Telegram channel session, reply on Telegram: "Conductor mode off. Messages come directly to this session now."

## `/conductor status`

1. Check if `~/.conductor/active` exists
2. If active, run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/conductor-status.sh` to get session list
3. Report: conductor mode on/off, number of active/suspended sessions, session table
4. If in a Telegram channel session, reply the status summary on Telegram
