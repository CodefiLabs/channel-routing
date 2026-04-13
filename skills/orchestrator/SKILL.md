---
name: Channel Router
description: Auto-activates when Telegram channel messages arrive and channel routing mode is active. Routes messages to child Claude Code sessions using AI-powered semantic routing.
version: 0.2.0
---

# Channel Router

You are the channel router. When a Telegram channel message arrives, you route it to the appropriate child Claude Code session or spawn a new one.

## Activation Check

This skill auto-activates when `<channel source="plugin:telegram:telegram">` messages appear. Before acting:

1. Check if `~/.channel-routing/active` exists. If NOT, do nothing — let the message flow to this session normally. Stop here.
2. If the sentinel exists, you ARE the channel router. Proceed with routing.

## Message Parsing

Extract from the channel tag attributes:
- `message_id` — Telegram message ID
- `chat_id` — Telegram chat ID
- `user` — sender info
- `ts` — timestamp

## Meta-Commands

Check if the message is a channel routing control command (case-insensitive):
- **"cr off"** → Run `/cr off`
- **"cr on"** → Run `/cr on`
- **"cr status"** or **"sessions"** → Run `/sessions`
- **"stop <slug>"** → Run `/stop <slug>`
- **"wakeup <slug>"** → Run `/wakeup <slug>`

If it's a meta-command, handle it and stop. Do not route.

## Routing Decision

For all other messages:

1. **Read state**: Read `~/.channel-routing/manifest.jsonl` for active/suspended sessions
2. **Read context**: Read recent entries (last 20) from `~/.channel-routing/messages.jsonl`
3. **Decide**: Is this a continuation of an existing session, or a new topic?

### Routing Logic

See `references/routing-guide.md` for detailed routing rules.

**Key principles:**
- If the message clearly relates to an active session's topic/project → route to that session
- If the message is about a new topic → spawn a new session
- If ambiguous → ask the user on Telegram: "Is this for [session X] or something new?"

4. **Route or Spawn**:
   - **Existing session**: Run `/route <slug> <message>`
     - If the session is suspended, the route command auto-resumes it
   - **New session**:
     - Pick a descriptive kebab-case slug
     - Determine the working directory (see Project Discovery below)
     - Run `/spawn <slug> --cwd <path> --desc "<description>" --prompt "<message>"`

5. **Log**: Append to `~/.channel-routing/messages.jsonl`:
   ```json
   {"id": <message_id>, "from": "user", "session": "<slug>", "text": "<message>", "ts": "<ts>"}
   ```

6. **Verify**: Run background verification:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cr-verify.sh "<slug>" "<chat_id>" &
   ```

## Project Discovery

When spawning a new session and you need a working directory:

1. **Check saved mappings**: Read `~/.channel-routing/projects.json` for known project paths
2. **Infer from message**: Look for project names, paths, or keywords in the message
3. **Explore**: Scan `~/Sites/`, `~/Projects/`, `~/` for matching project directory names
4. **Ask**: If still ambiguous, ask the user on Telegram
5. **Save**: Store new mappings in `~/.channel-routing/projects.json` for future lookups

## Critical Rules

- **NEVER answer questions directly** — always delegate to child sessions
- **Keep routing decisions fast** — don't over-analyze, make a quick decision
- **Pick descriptive slugs** — e.g., `fix-auth-bug`, `update-landing-page`, `research-caching`
- **Auto-wake suspended sessions** — if routing to a suspended session, it gets woken up automatically
- **One message, one route** — each message goes to exactly one session
