---
paths:
  - "mcp/**"
---

# MCP Server

`mcp/server.rb` offers the API as 25 tools over stdio. Only protocol messages may reach stdout.

```bash
cd mcp && bundle install
claude mcp add chronicler \
  -e CHRONICLER_URL=https://chronicler.devleo.me \
  -e CHRONICLER_API_KEY=your-key \
  -- ruby /absolute/path/to/chronicler/mcp/server.rb
```

- Names, descriptions and inputs are fixed by `contract/mcp_tools.json`, which `spec/mcp` checks.
- Errors of the API come back as results. `get_summary` returns plain text, and deletions `{success, status}`.
- `groupIds` and `characterIds` in updates replace the whole list.
