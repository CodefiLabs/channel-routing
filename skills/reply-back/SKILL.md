---
name: Channel Routing Reply-Back
description: Auto-activates in child channel-routing sessions to enable replying to Telegram. Detects when CR_SLUG and CR_CHAT_ID environment variables are present.
version: 0.2.0
---

# Reply-Back to Telegram

You are running as a child session managed by the channel router. When you have results, findings, or responses to share with the user, send them back to Telegram.

## When to Reply

- When you've completed a task or significant milestone
- When you need to ask the user a clarifying question
- When you encounter an error or blocker the user should know about
- When you have interim progress worth sharing

## How to Reply

Use the `/reply-back` command:

```
/reply-back <your message text>
```

This sends your message to the Telegram chat where the original request came from.

## Activation Check

This skill activates when the environment variables `CR_SLUG` and `CR_CHAT_ID` are set. These are injected by the channel router when spawning your session.

If these variables are not present, this skill does not apply.

## Guidelines

- Keep messages concise — Telegram messages should be scannable
- Use Markdown formatting (Telegram supports basic Markdown)
- For code blocks, use triple backticks
- For long outputs, summarize the key points rather than dumping everything
- Send a final reply when your task is complete
- If you're working on something that takes a while, send a brief progress update
