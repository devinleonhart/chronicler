---
paths:
  - "mcp/**"
---

# MCP Server

`mcp/server.ts` is a Model Context Protocol server that exposes the full Chronicler API as
callable tools. It communicates over stdio and requires the Nuxt app to be running.

## Running

```bash
pnpm dev          # must be running first
pnpm mcp          # starts the MCP server (separate terminal)
```

The server targets `http://localhost:3000` by default.

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CHRONICLER_URL` | No | Base URL of the Nuxt server (default: `http://localhost:3000`) |
| `CHRONICLER_API_KEY` | When `API_KEY` is set on the server | Must match the `API_KEY` env var on the Nuxt server |

## Authentication

Set `API_KEY` on the Nuxt server to enable auth. When set, every `/api/*` request
must include `Authorization: Bearer <key>` or it receives a `401`.

Local dev without `API_KEY` set: no auth enforced.
Production with `API_KEY` set: all unauthenticated requests are rejected.

## Connecting to Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "chronicler": {
      "command": "pnpm",
      "args": ["--prefix", "/absolute/path/to/chronicler", "mcp"],
      "env": {
        "CHRONICLER_URL": "https://your-production-server.com",
        "CHRONICLER_API_KEY": "your-secret-key"
      }
    }
  }
}
```

## Connecting to Claude Code

```bash
claude mcp add chronicler \
  -e CHRONICLER_URL=https://your-production-server.com \
  -e CHRONICLER_API_KEY=your-secret-key \
  -- pnpm --prefix /absolute/path/to/chronicler mcp
```

## Available tools (18)

| Resource | Tools |
|----------|-------|
| Characters | `list_characters`, `get_character`, `create_character`, `update_character`, `delete_character` |
| Groups | `list_groups`, `get_group`, `create_group`, `update_group`, `delete_group` |
| Events | `list_events`, `get_event`, `create_event`, `update_event`, `delete_event` |
| Settings | `get_settings`, `update_settings` |
| Summary | `get_summary` |

## Notes

- All write tools go through the existing REST API, so universe date validation and character
  lifespan checks still apply.
- `delete_event` will fail on the Current Day event (the API prevents this).
- `update_character` / `update_event` `groupIds` / `characterIds` are **full replacements**,
  not additions — pass the complete desired list.
- `get_summary` returns plain text, not JSON.
