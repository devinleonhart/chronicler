---
paths:
  - "app/mcp/**"
  - "app/operations/**"
  - "app/controllers/mcp_controller.rb"
  - "mcp/**"
---

# MCP

`POST /mcp` offers the API's operations as 25 tools, stateless, over the tailnet only.

- A token (`McpToken`) carries read, write or delete scopes. `list_`, `get_` and `find_` tools need read, `delete_` tools delete, and the rest write.
- Tools and API controllers call the same operations, which give data or raise `Rejection`.
- Names, descriptions and inputs are fixed by `contract/mcp_tools.json`.
- Content is the API's JSON, errors included; plain text for `get_summary`; `{success, status}` for deletions.
- The Host is read from the header itself, since Rails' `request.host` believes X-Forwarded-Host.
- The log names the token, machine and tool, never a token or an argument.

`mcp/server.rb` is the earlier stdio server. `spec/requests/mcp_parity_spec.rb` compares the two until it is removed.
