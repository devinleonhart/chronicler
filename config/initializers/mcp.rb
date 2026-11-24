# Each token belongs to the one user.
ActiveSupport.on_load(:tailnet_mcp_token) { belongs_to :user, inverse_of: :mcp_tokens }

TailnetMcp.configure do |config|
  config.name = "chronicler"
  config.token_prefix = "chr"
  # The only host that may be used for MCP. Without it, /mcp does not exist.
  config.host = ENV["MCP_HOST"].presence
  config.tool_sets = -> { ChroniclerMcp.tool_sets }
  config.token_attributes = ->(_) { { user: User.first || raise(TailnetMcp::Refused, "There is no user") } }
end
