require "rails_helper"
require "open3"

# The MCP server runs as Claude runs it, against this application served over HTTP.
RSpec.describe "McpServer" do
  let(:api) { Capybara::Server.new(Rails.application).boot }
  let(:api_url) { "http://#{api.host}:#{api.port}" }
  let(:key) { "secret" }

  before do
    allow(Rails.configuration.x).to receive(:api_key).and_return("secret")
    api
    start
  end

  after do
    [@input, @output, @errors].each(&:close) # rubocop:disable RSpec/InstanceVariable
    @process.value # rubocop:disable RSpec/InstanceVariable
  end

  # rubocop:disable RSpec/InstanceVariable
  def start
    environment = { "CHRONICLER_URL" => api_url, "CHRONICLER_API_KEY" => key }
    Bundler.with_original_env do
      @input, @output, @errors, @process = Open3.popen3(environment, "ruby", Rails.root.join("mcp/server.rb").to_s)
    end
    request("initialize", protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "spec", version: "1" })
    @input.puts({ jsonrpc: "2.0", method: "notifications/initialized" }.to_json)
  end

  # Every line on stdout must be a protocol message.
  def request(method, params = {})
    @id = @id.to_i + 1
    @input.puts({ jsonrpc: "2.0", id: @id, method:, params: }.to_json)
    line = Timeout.timeout(20) { @output.gets }
    raise "No answer: #{@errors.read}" if line.nil?

    message = JSON.parse(line)
    raise "Unexpected message: #{line}" unless message["id"] == @id

    message
  end
  # rubocop:enable RSpec/InstanceVariable

  def call(tool, arguments = {})
    request("tools/call", name: tool, arguments:).fetch("result")
  end

  def text(tool, arguments = {})
    result = call(tool, arguments)
    expect(result["isError"]).not_to be(true), result.inspect
    result.fetch("content").sole.fetch("text")
  end

  def data(tool, arguments = {})
    JSON.parse(text(tool, arguments))
  end

  def rest(path)
    Net::HTTP.get(URI.join(api_url, path), { "Authorization" => "Bearer secret" }).force_encoding("UTF-8")
  end

  def rest_json(path)
    JSON.parse(rest(path))
  end

  # Drops what only the schema libraries decide: the dialect, the safe-integer limit, and empty lists.
  def normalize(schema)
    case schema
    when Hash
      kept = schema.except("$schema", "maximum")
      kept.to_h { |name, value| [name, normalize(value)] }.reject { |name, value| name == "required" && value.empty? }
    when Array then schema.map { |item| normalize(item) }
    else schema
    end
  end

  def tools(list)
    list.to_h do |tool|
      schema = normalize(tool["inputSchema"])
      schema["required"] = schema["required"].sort if schema["required"]
      [tool["name"], [tool["description"], { "properties" => {} }.merge(schema)]]
    end
  end

  it "offers the recorded tools" do
    recorded = JSON.parse(Rails.root.join("contract/mcp_tools.json").read).fetch("tools")
    offered = request("tools/list").dig("result", "tools")

    expect(offered.size).to eq(25)
    expect(tools(offered)).to eq(tools(recorded))
  end

  it "reads with every reading tool" do
    create(:universe_setting)
    group = create(:group, name: "Heroés")
    character = create(:character, name: "Aria", birth_date: "2200-01-01", groups: [group])
    event = create(:event, start_date: "2250-01-01", characters: [character])
    create(:character, name: "Bran")

    expect(data("get_settings")).to eq(rest_json("/api/settings"))
    expect(data("list_groups")).to eq(rest_json("/api/groups"))
    expect(data("get_group", id: group.id)).to eq(rest_json("/api/groups/#{group.id}"))
    expect(data("list_characters")).to eq(rest_json("/api/characters"))
    filters = { name: "ar", groupId: group.id, birthYear: 2200 }
    expect(data("list_characters", filters)).to eq(rest_json("/api/characters?#{filters.to_query}"))
    expect(data("list_characters", filters).size).to eq(1)
    expect(data("get_character", id: character.id)).to eq(rest_json("/api/characters/#{character.id}"))
    expect(data("get_character_events", id: character.id))
      .to eq(rest_json("/api/characters/#{character.id}/events"))
    expect(data("find_placeholder_characters").pluck("name")).to eq(["Aria"])
    expect(data("find_placeholder_characters", birthDate: "2270-01-01").pluck("name")).to eq(["Bran"])
    expect(data("list_events")).to eq(rest_json("/api/events"))
    filters = { name: "event", characterId: character.id, startAfter: "2249-01-01", startBefore: "2251-01-01" }
    expect(data("list_events", filters).pluck("id")).to eq([event.id])
    expect(data("get_event", id: event.id)).to eq(rest_json("/api/events/#{event.id}"))
    expect(text("get_summary", characterIds: [character.id]))
      .to eq(rest("/api/summary?characterIds=#{character.id}"))
  end

  it "writes with every writing tool" do
    create(:universe_setting)
    event_of = ->(id) { rest_json("/api/events/#{id}") }
    character_of = ->(id) { rest_json("/api/characters/#{id}") }

    expect(data("update_settings", name: "Renamed", currentDay: "2301-01-01")).to eq(rest_json("/api/settings"))

    group = data("create_group", name: "Heroes", description: nil)
    expect(group).to eq(rest_json("/api/groups/#{group['id']}"))
    expect(data("update_group", id: group["id"], description: "Brave")).to include("description" => "Brave")
    expect(data("update_group", id: group["id"], description: nil)).to include("description" => nil)

    character = data("create_character", name: "Aria", birthDate: "2270-01-01", groupIds: [group["id"]])
    expect(character).to eq(character_of[character["id"]])
    expect(data("update_character", id: character["id"], deathDate: "2299-01-01"))
      .to eq(character_of[character["id"]])
    expect(data("update_character", id: character["id"], deathDate: nil)).to include("deathDate" => nil)
    expect(data("remove_group_from_character", characterId: character["id"], groupId: group["id"]))
      .to include("characterGroups" => [])
    expect(data("add_group_to_character", characterId: character["id"], groupId: group["id"]))
      .to eq(character_of[character["id"]])
    expect(data("bulk_update_characters", updates: [{ id: character["id"], name: "Aria II" }]))
      .to eq([character_of[character["id"]]])

    fields = { name: "War", startDate: "2290-01-01", endDate: nil, characterIds: [character["id"]] }
    event = data("create_event", fields)
    expect(event).to eq(event_of[event["id"]])
    expect(data("update_event", id: event["id"], endDate: "2291-01-01")).to eq(event_of[event["id"]])
    expect(data("remove_character_from_event", eventId: event["id"], characterId: character["id"]))
      .to include("eventCharacters" => [])
    expect(data("add_character_to_event", eventId: event["id"], characterId: character["id"]))
      .to eq(event_of[event["id"]])

    { "delete_event" => event, "delete_character" => character, "delete_group" => group }.each do |tool, record|
      expect(data(tool, id: record["id"])).to eq("success" => true, "status" => 204)
      expect(data(tool, id: record["id"])).to eq("success" => false, "status" => 404)
    end
  end

  it "returns the API's errors as results" do
    expect(data("get_group", id: 999_999)).to eq("error" => "Group not found")
    expect(JSON.parse(text("get_summary", characterIds: [999_999])))
      .to eq("error" => "No characters found for the given IDs")
  end

  it "refuses arguments outside the schema, and keeps running" do
    refused = [["get_group", {}], ["get_group", { id: "1" }], ["get_group", { id: 0 }], ["create_group", { name: "" }],
               ["create_event", { name: "x", startDate: "soon" }], ["get_summary", { characterIds: [] }]]
    refused.each do |tool, arguments|
      message = request("tools/call", name: tool, arguments:)
      expect(message["error"] || message.dig("result", "isError")).to be_truthy
    end

    expect(Group.count).to eq(0)
    expect(data("list_groups")).to eq([])
  end

  context "with a wrong key" do
    let(:key) { "wrong" }

    it "returns the Unauthorized error without stopping" do
      2.times { expect(data("list_groups")).to eq("error" => "Unauthorized") }
      expect(data("delete_group", id: 1)).to eq("success" => false, "status" => 401)
    end
  end

  context "without a reachable application" do
    let(:api_url) { "http://127.0.0.1:1" }

    it "returns an error result without stopping" do
      2.times { expect(call("list_groups")["isError"]).to be(true) }
    end
  end
end
