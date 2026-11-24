require "rails_helper"
require "tailnet_mcp/rspec"

RSpec.describe "MCP endpoint" do
  include_context "with tailnet MCP"

  let(:user) { create(:user) }

  def issue_token(*scopes, machine: "laptop")
    TailnetMcp::Token.issue!(user:, machine:, scopes: scopes.presence || ["read"])
  end

  # The gem's own cases, beside the application's in mcp_security_spec.rb.
  it_behaves_like "a tailnet MCP endpoint", tool: "list_groups", page: "/events"
end
