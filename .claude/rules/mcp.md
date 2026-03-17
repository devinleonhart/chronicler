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

The server targets `http://localhost:3000` by default. Override with:

```bash
CHRONICLER_URL=http://my-server pnpm mcp
```

## Connecting to Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "chronicler": {
      "command": "pnpm",
      "args": ["--prefix", "/absolute/path/to/chronicler", "mcp"],
      "env": {
        "CHRONICLER_URL": "http://localhost:3000"
      }
    }
  }
}
```

## Connecting to Claude Code

```bash
claude mcp add chronicler -- pnpm --prefix /absolute/path/to/chronicler mcp
```

Or with a custom URL:

```bash
claude mcp add chronicler -e CHRONICLER_URL=http://localhost:3000 -- pnpm --prefix /absolute/path/to/chronicler mcp
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
