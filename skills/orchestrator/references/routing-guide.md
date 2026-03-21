# Routing Decision Guide

## Decision Tree

```
Message arrives
  ├─ Is it a meta-command? → Handle directly (don't route)
  ├─ Are there 0 active sessions? → Spawn new session
  ├─ Is there exactly 1 active session?
  │   ├─ Message seems related → Route to it
  │   └─ Message is clearly a different topic → Spawn new session
  └─ Are there 2+ active sessions?
      ├─ Message clearly matches one session → Route to it
      ├─ Message is ambiguous → Ask user on Telegram
      └─ Message is clearly new → Spawn new session
```

## Matching Signals

**Strong match** (route confidently):
- Message mentions the same project name as a session
- Message references work the session is doing ("how's that auth fix going?")
- Message is a follow-up question in the same domain
- Message uses reply-to pointing at a session's previous message (future)

**Weak match** (consider but don't rely on alone):
- Message is in the same general domain (e.g., "frontend" when a frontend session exists)
- Session was recently active

**No match** (spawn new):
- Message is about a completely different project
- Message starts a new thread of work ("Can you help me set up X?")
- Message explicitly says "new task" or "different thing"

## Session Slug Naming

Pick slugs that are:
- Descriptive of the task: `fix-auth-middleware`, `add-pricing-page`
- Kebab-case, lowercase
- 2-4 words typically
- Based on the project and/or task: `tq-fix-routing`, `circlechurch-update-nav`

## Ambiguity Resolution

When uncertain, prefer:
1. Routing to the most recently active session (if the topic could belong to it)
2. Asking the user (if truly ambiguous between 2+ sessions)
3. Spawning new (if the message feels like a fresh request)

Template for asking:
> "Is this for **[session-slug]** ([description]) or something new?"

## Message Logging Format

Every routed or spawned message gets logged to `~/.conductor/messages.jsonl`:

```json
{"id": 83, "from": "user", "session": "fix-auth-bug", "text": "Fix the auth middleware", "ts": "2026-03-21T16:05:00Z"}
```

This log serves dual purpose:
1. **Now**: Context for AI routing decisions
2. **Future**: Reply-to lookup table when Anthropic adds reply_to to channel notifications
