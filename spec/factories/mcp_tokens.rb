FactoryBot.define do
  factory :mcp_token do
    user
    machine { "cocoa" }
    scopes { ["read"] }
    digest { McpToken.digest_of(McpToken.generate_text) }
    expires_at { 90.days.from_now }
  end
end
