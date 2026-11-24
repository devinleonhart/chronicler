require "rails_helper"
require "open3"

# Boots production, whose host settings differ, and asks it directly.
RSpec.describe "Hosts" do
  it "keeps the pages from the MCP host, and MCP from the public one" do
    script = <<~RUBY
      ask = lambda do |host, path, headers = {}|
        env = Rack::MockRequest.env_for("https://\#{host}\#{path}", method: path == "/mcp" ? "POST" : "GET", **headers)
        env["HTTP_HOST"] = host
        Rails.application.call(env).first
      end
      site, mcp = "chronicler.devleo.me", "lucky.example.ts.net:8443"
      puts JSON.generate(
        pages: ["/events", "/session/new", "/api/groups", "/", "/mcp/", "/mcp/x", "/mcpx"].map { |path| ask.(mcp, path) },
        page_on_site: ask.(site, "/events"), api_on_site: ask.(site, "/api/groups"),
        mcp_on_site: ask.(site, "/mcp"), forwarded: ask.(site, "/mcp", "HTTP_X_FORWARDED_HOST" => mcp),
        forwarded_page: ask.(mcp, "/events", "HTTP_X_FORWARDED_HOST" => site),
        mcp: ask.(mcp, "/mcp"), up: ask.("localhost", "/up"), other: ask.("evil.example", "/mcp")
      )
    RUBY
    env = { "RAILS_ENV" => "production", "SECRET_KEY_BASE" => "x" * 64, "API_KEY" => "secret", "APP_HOST" => nil,
            "MCP_HOST" => "lucky.example.ts.net", "RAILS_LOG_LEVEL" => "fatal",
            "DATABASE_URL" => ENV.fetch("TEST_DATABASE_URL") }
    output, status = Open3.capture2e(env, Rails.root.join("bin/rails").to_s, "runner", script)
    expect(status).to be_success, output

    expect(JSON.parse(output.lines.grep(/\A{/).last, symbolize_names: true)).to eq(
      pages: [403] * 7, page_on_site: 303, api_on_site: 401, mcp_on_site: 403, forwarded: 403, forwarded_page: 403,
      mcp: 401, up: 200, other: 403
    )
  end
end
