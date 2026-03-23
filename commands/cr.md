---
name: cr
description: Toggle channel routing mode on/off or check status
---

# /cr — Channel Routing Mode Toggle

Manage channel routing mode for this session. Channel routing mode enables AI-powered message routing from Telegram to multiple child Claude Code sessions.

**Arguments**: `on`, `off`, or `status` (default: `status`)

Parse the arguments provided after `/cr`.

## `/cr on`

1. Create the state directory if needed: `mkdir -p ~/.channel-routing`
2. Write the sentinel file `~/.channel-routing/active` with content: the current timestamp
3. Confirm activation to the user
4. If in a Telegram channel session, reply on Telegram: "Channel routing active. I'll route your messages to sessions."

## `/cr off`

1. Remove `~/.channel-routing/active` if it exists
2. Confirm deactivation to the user
3. If in a Telegram channel session, reply on Telegram: "Channel routing off. Messages come directly to this session now."

## `/cr status`

1. Check if `~/.channel-routing/active` exists
2. If active, run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-status.sh` to get session list
3. Report: channel routing mode on/off, number of active/suspended sessions, session table
4. If in a Telegram channel session, reply the status summary on Telegram
