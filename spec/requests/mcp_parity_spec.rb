require "rails_helper"
require "open3"

# The tool of each route, with the argument that an id in the address becomes.
module McpParity
  ROUTES = {
    "GET /api/settings" => "get_settings", "PUT /api/settings" => "update_settings",
    "GET /api/groups" => "list_groups", "POST /api/groups" => "create_group", "GET /api/groups/:id" => "get_group",
    "PUT /api/groups/:id" => "update_group", "DELETE /api/groups/:id" => "delete_group",
    "GET /api/characters" => "list_characters", "POST /api/characters" => "create_character",
    "PUT /api/characters/bulk" => "bulk_update_characters",
    "GET /api/characters/placeholders" => "find_placeholder_characters",
    "GET /api/characters/:id" => "get_character", "PUT /api/characters/:id" => "update_character",
    "DELETE /api/characters/:id" => "delete_character", "GET /api/characters/:id/events" => "get_character_events",
    "POST /api/characters/:characterId/groups" => "add_group_to_character",
    "DELETE /api/characters/:characterId/groups/:groupId" => "remove_group_from_character",
    "GET /api/events" => "list_events", "POST /api/events" => "create_event", "GET /api/events/:id" => "get_event",
    "PUT /api/events/:id" => "update_event", "DELETE /api/events/:id" => "delete_event",
    "POST /api/events/:eventId/characters" => "add_character_to_event",
    "DELETE /api/events/:eventId/characters/:characterId" => "remove_character_from_event",
    "GET /api/summary" => "get_summary"
  }.freeze

  # Whether a request matches a route's verb and address.
  def self.match?(route, request)
    verb, pattern = route.split(" ", 2)
    parts, segments = [pattern, path(request)].map { |text| text.split("/") }
    verb == request["method"] && parts.size == segments.size &&
      parts.zip(segments).all? { |part, segment| part.start_with?(":") || part == segment }
  end

  def self.path(request)
    request["path"].split("?").first
  end
end

# Sends the contract's requests, as tool calls, through the stdio server and through /mcp,
# from the same state, and compares what comes back and what is left.
RSpec.describe "MCP parity" do
  include_context "with MCP"

  let(:api) { Capybara::Server.new(Rails.application).boot }

  before { allow(Rails.configuration.x).to receive(:api_key).and_return("secret") }

  def tool_calls(section)
    requests = JSON.parse(Rails.root.join("contract/requests.json").read).fetch("sections")
    requests = requests.find { |candidate| candidate["name"] == section }.fetch("requests")
    requests.reject { |request| request.key?("raw") }.filter_map { |request| tool_call(request) }
  end

  def tool_call(request)
    route = McpParity::ROUTES.keys.find { |candidate| McpParity.match?(candidate, request) }
    parts = route.split(" ", 2).last.split("/").zip(McpParity.path(request).split("/"))
    ids = parts.select { |part, _| part.start_with?(":") }.to_h { |part, id| [part.delete_prefix(":"), typed(id)] }
    [McpParity::ROUTES.fetch(route), ids.merge(filters(request["path"].split("?")[1])).merge(request["body"] || {})]
  end

  def filters(query)
    Rack::Utils.parse_query(query.to_s).to_h do |name, value|
      next [name, value.to_s.split(",").map { |id| typed(id) }] if name == "characterIds"

      [name, %w[groupId birthYear characterId].include?(name) ? typed(value) : value]
    end
  end

  def typed(text)
    text.to_s.match?(/\A\d+\z/) ? text.to_i : text
  end

  def load_sample
    allow(Rails.env).to receive(:development?).and_return(true)
    load Rails.root.join("db/seeds.rb")
  end

  # Everything the block changes is undone, ids included. A transaction block would keep the
  # connection from the thread that serves the API.
  def undone
    connection = ActiveRecord::Base.connection
    %w[universe_settings groups characters events].each { |table| connection.reset_pk_sequence!(table) }
    connection.begin_transaction(joinable: false)
    yield
  ensure
    connection.rollback_transaction
  end

  def through_stdio(calls)
    environment = { "CHRONICLER_URL" => "http://#{api.host}:#{api.port}", "CHRONICLER_API_KEY" => "secret" }
    Bundler.with_original_env do
      Open3.popen3(environment, "ruby", Rails.root.join("mcp/server.rb").to_s) do |input, output, _, _|
        ask = lambda do |id, method, params|
          input.puts({ jsonrpc: "2.0", id:, method:, params: }.to_json)
          JSON.parse(Timeout.timeout(20) { output.gets })
        end
        ask.call(0, "initialize", { protocolVersion: "2025-06-18", capabilities: {},
                                    clientInfo: { name: "spec", version: "1" } })
        calls.each.with_index(1).map do |(name, arguments), id|
          content(ask.call(id, "tools/call", { name:, arguments: }))
        end
      end
    end
  end

  def through_mcp(calls)
    calls.map do |name, arguments|
      ChroniclerMcp::Limits.reset
      content(call_tool(name, arguments, token:))
    end
  end

  # An error is now marked as one, so that mark is left out.
  def content(answer)
    answer["error"] ? [answer["error"]["code"], answer["error"]["message"]] : answer.dig("result", "content")
  end

  def compare(calls)
    api
    token
    freeze_time
    expected = undone { [through_stdio(calls), all_rows] }
    actual = undone { [through_mcp(calls), all_rows] }

    calls.each_with_index do |call, index|
      expect(actual.first[index]).to eq(expected.first[index]), "#{call.inspect}\nstdio: #{expected.first[index]}\n" \
                                                                "/mcp:  #{actual.first[index]}"
    end
    expect(actual.last).to eq(expected.last)
    expected.first
  end

  %w[settings groups characters events summary].each do |section|
    it "holds for #{section}" do
      load_sample
      calls = tool_calls(section)
      contents = compare(calls)

      expect(calls.size).to be > 10
      expect(contents.flatten.grep(Hash).pluck("text").grep(/"error"/)).not_to be_empty
    end
  end

  it "holds for an empty universe" do
    compare(tool_calls("empty"))

    expect(all_rows.values).to all(be_empty)
  end

  it "covers every tool" do
    names = %w[settings groups characters events summary].flat_map { |section| tool_calls(section).map(&:first) }

    expect(names.uniq).to match_array(McpParity::ROUTES.values)
    expect(McpParity::ROUTES.size).to eq(25)
  end

  it "holds for other arguments" do
    load_sample
    contents = compare(
      [
        ["list_characters", { name: "" }], ["list_characters", { name: "linda", groupId: 9, birthYear: 2231 }],
        ["list_characters", { name: nil }], ["list_characters", { groupId: "6" }], ["list_characters", { groupId: 0 }],
        ["list_characters", { unknown: 1 }], ["list_characters", { groupId: 99_999_999_999 }],
        ["list_events", { name: "é & =+%", startAfter: "2290-01-01" }], ["list_events", { startAfter: "soon" }],
        ["get_group", { id: 99_999_999_999 }], ["get_group", { id: 6, extra: true }], ["get_group", {}],
        ["get_event", { id: 1.0 }], ["get_summary", { characterIds: [13, 13, 7] }],
        ["get_summary", { characterIds: [99_999_999_999] }], ["get_summary", { characterIds: [] }],
        ["create_group", { name: "G", description: nil, id: 5 }], ["create_group", { name: "x" * 256 }],
        ["update_character", { id: 1, deathDate: nil }], ["update_character", { id: 1 }],
        ["update_character", { id: 1, name: nil }], ["update_event", { id: 4, endDate: nil, characterIds: [] }],
        ["update_event", { id: 4, characterIds: [1, 999_999] }], ["bulk_update_characters", { updates: [] }],
        ["bulk_update_characters", { updates: [{ id: 1, name: "One", extra: 1 }, { id: 2, groupIds: [1, 1] }] }],
        ["add_group_to_character", { characterId: 99_999_999_999, groupId: 1 }],
        ["add_group_to_character", { characterId: 1, groupId: 99_999_999_999 }],
        ["remove_character_from_event", { eventId: 1, characterId: 99_999_999_999 }],
        ["delete_event", { id: 75 }], ["delete_event", { id: 99_999_999_999 }], ["delete_group", { id: 6 }],
        ["drop_everything", {}]
      ]
    )

    expect(contents.size).to eq(32)
  end
end
