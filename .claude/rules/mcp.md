---
paths:
  - "app/mcp/**"
  - "app/operations/**"
  - "config/initializers/mcp.rb"
---

# MCP

`POST /mcp` offers the API's operations as 25 tools, stateless, over the tailnet only.

- The endpoint, limits, tokens and token commands come from the `tailnet_mcp` gem (`devinleonhart/tailnet-mcp`), pinned by commit. Its migration is not installed: `mcp_tokens` was made here, with `user_id` and an array of scopes.
- A token (`TailnetMcp::Token`) carries read, write or delete scopes. `list_`, `get_` and `find_` tools need read, `delete_` tools delete, and the rest write.
- Tools and API controllers call the same operations, which give data or raise `Rejection`.
- Names, descriptions and inputs are fixed by `contract/mcp_tools.json`.
- Content is the API's JSON, errors included; plain text for `get_summary`; `{success, status}` for deletions.
- The Host is read from the header itself, since Rails' `request.host` believes X-Forwarded-Host.
- The log names the token, machine and tool, never a token or an argument.

`spec/fixtures/files/mcp_parity.json` is what the earlier stdio server answered; `/mcp` must answer the same.

On a machine, `~/.local/bin/mcp-token` keeps the token in its keyring, and Claude reads it through `headersHelper`.
