# The only host that may be used for MCP. Without it, /mcp does not exist.
Rails.application.config.x.mcp_host = ENV["MCP_HOST"].presence
