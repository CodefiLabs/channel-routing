# channel-routing

A Claude Code plugin that routes Telegram messages to multiple parallel Claude Code sessions using AI-powered semantic routing.

Send a message in Telegram. The router reads your intent, finds (or spawns) the right Claude Code session, and injects the message — no channel-picking required.

## How It Works

```
Telegram message
    |
    v
Orchestrator skill (AI routing decision)
    |
    +---> Existing session? --> /route to tmux pane
    |
    +---> New topic? ---------> /spawn new session
    |
    +---> Ambiguous? ---------> Ask user on Telegram
    |
    v
Child session works, replies via /reply-back
    |
    v
Telegram reply
```

1. **You send a message** in Telegram
2. **The orchestrator** reads active sessions and recent message history, then decides: route to an existing session or spawn a new one
3. **Child sessions** run as full interactive `claude` instances in tmux panes — same tools, plugins, and MCP servers you'd have at the terminal
4. **Sessions reply** back to Telegram when they have results

## Install

```bash
# Add the CodefiLabs marketplace
/plugin marketplace add CodefiLabs/marketplace

# Install the plugin
/plugin install channel-routing@CodefiLabs/marketplace
```

Requires the official [Telegram channel plugin](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/telegram) to be configured first.

### Dependencies

- `tmux`
- `jq`
- `curl`
- `bash` 4.0+

## Usage

### Toggle routing mode

From Telegram or the CLI:

```
cr on       # Start routing messages to sessions
cr off      # Stop routing, messages go to this session
cr status   # Show active/suspended sessions
```

### Commands

| Command | Description |
|---------|-------------|
| `/cr on\|off\|status` | Toggle routing mode |
| `/spawn <slug> [--cwd <path>] [--desc "..."] [--prompt "..."]` | Create a child session |
| `/route <slug> <message>` | Send a message to a session |
| `/resume <slug>` | Resume a suspended session |
| `/stop <slug>` | Stop a session |
| `/sessions` | List all sessions |
| `/reply-back <text>` | Send a response to Telegram (used by child sessions) |

### Example

```
You (Telegram): Fix the auth middleware in project-a
  --> Router spawns session "fix-auth-middleware" in ~/Sites/codefi/project-a

You (Telegram): Also update the landing page copy
  --> Router spawns session "update-landing-page" in ~/Sites/codefi/marketing

You (Telegram): Actually make the error message friendlier
  --> Router routes to "fix-auth-middleware" (related to auth work)
```

## Architecture

### Routing

The orchestrator skill uses semantic analysis to match messages to sessions:

- **Strong match**: message mentions a project/topic an active session is working on
- **Weak match**: same domain, recent activity
- **No match**: clearly a new topic — spawn a new session
- **Ambiguous**: ask the user on Telegram before routing

### Sessions

Each child session is a full `claude` CLI process in a tmux pane with:
- `CR_SLUG` and `CR_CHAT_ID` environment variables for identity
- A `SessionEnd` hook that logs suspension to the manifest
- Access to all your plugins, MCP servers, and tools

### State

All state lives in `~/.channel-routing/`:

| File | Format | Purpose |
|------|--------|---------|
| `active` | Timestamp | Sentinel — exists when routing is on |
| `manifest.jsonl` | JSONL | Session lifecycle events (spawn, route, suspend, resume) |
| `messages.jsonl` | JSONL | All routed and replied messages |
| `projects.json` | JSON | Saved project-name-to-path mappings |

### Health checks

A background verification script runs 30 seconds after each spawn/route to confirm the tmux pane is alive and not stuck on an error.

## Plugin structure

```
channel-routing/
  .claude-plugin/plugin.json
  commands/          # Slash command definitions
  skills/
    orchestrator/    # AI routing logic
    reply-back/      # Child session reply capability
  scripts/           # Bash implementations (cr-spawn, cr-route, etc.)
  hooks/             # PostToolUse hook for message logging
```

## License

MIT
