# Calls /mcp as a client does.
module McpHelpers
  MCP_HOST = "lucky.example.ts.net".freeze

  def issue_token(*scopes, machine: "cocoa")
    TailnetMcp::Token.issue!(user:, machine:, scopes: scopes.presence || ["read"])
  end

  def mcp_post(body, token: nil, host: MCP_HOST, headers: {})
    all = { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream", "Host" => host }
    all["Authorization"] = "Bearer #{token}" if token
    post "/mcp", params: body.is_a?(String) ? body : body.to_json, headers: all.merge(headers)
  end

  def mcp_request(method, params = {}, **)
    mcp_post({ jsonrpc: "2.0", id: 1, method:, params: }, **)
    response.parsed_body
  end

  def call_tool(name, arguments = {}, token:)
    mcp_request("tools/call", { name:, arguments: }, token:)
  end

  # The text of a call, or the protocol's error.
  def tool_text(name, arguments = {}, token:)
    body = call_tool(name, arguments, token:)
    body["error"] ? body["error"].except("data") : body.dig("result", "content").sole.fetch("text")
  end

  def tool_names(token)
    mcp_request("tools/list", token:).dig("result", "tools").pluck("name")
  end

  def queries(&)
    list = []
    callback = ->(*, payload) { list << payload[:sql] unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)
    list
  end
end

RSpec.shared_context "with MCP" do
  include McpHelpers

  let(:user) { create(:user) }
  let(:token) { issue_token("read", "write", "delete") }
  let(:reader) { issue_token("read") }
  let(:writer) { issue_token("read", "write") }

  before do
    allow(TailnetMcp.configuration).to receive(:host).and_return(McpHelpers::MCP_HOST)
    TailnetMcp::Limits.reset
  end
end
