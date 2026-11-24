FactoryBot.define do
  factory :mcp_token, class: "TailnetMcp::Token" do
    user
    machine { "cocoa" }
    scopes { ["read"] }
    digest { TailnetMcp::Token.digest_of(TailnetMcp::Token.generate_text) }
    expires_at { 90.days.from_now }
  end
end
