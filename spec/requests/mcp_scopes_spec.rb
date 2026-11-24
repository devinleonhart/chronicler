require "rails_helper"

RSpec.describe "MCP scopes" do
  include_context "with MCP"

  let(:recorded) { JSON.parse(Rails.root.join("contract/mcp_tools.json").read).fetch("tools") }

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

  def described(list)
    list.to_h do |tool|
      schema = normalize(tool["inputSchema"])
      schema["required"] = schema["required"].sort if schema["required"]
      [tool["name"], [tool["description"], { "properties" => {} }.merge(schema)]]
    end
  end

  def offered(token)
    mcp_request("tools/list", token:).dig("result", "tools")
  end

  it "offers the recorded tools to a token with every scope" do
    expect(described(offered(token))).to eq(described(recorded))
  end

  it "offers fewer to narrower tokens" do
    names = recorded.pluck("name")
    reading = names.grep(/\A(list|get|find)_/)

    expect(tool_names(reader)).to match_array(reading)
    expect(tool_names(writer)).to match_array(names.grep_v(/\Adelete_/))
    expect([reading.size, tool_names(writer).size, names.size]).to eq([10, 22, 25])
  end

  it "marks tools by what they do" do
    hints = offered(token).to_h do |tool|
      [tool["name"], tool["annotations"].values_at("readOnlyHint", "destructiveHint")]
    end

    hints.each do |name, hint|
      expect(hint).to eq([name.match?(/\A(list|get|find)_/), name.start_with?("delete_")])
    end
  end

  it "refuses tools outside the scope, and changes nothing" do
    group = create(:group)
    character = create(:character, groups: [group])
    event = create(:event, characters: [character])
    create(:universe_setting)
    ids = { id: character.id, characterId: character.id, groupId: group.id, eventId: event.id, name: "New",
            birthDate: "2270-01-01", startDate: "2290-01-01", updates: [{ id: character.id, name: "New" }] }
    before = all_rows
    [[reader, recorded.pluck("name").grep_v(/\A(list|get|find)_/)],
     [writer, recorded.pluck("name").grep(/\Adelete_/)]].each do |weak, names|
      names.each do |name|
        body = call_tool(name, ids, token: weak)
        expect(body["error"] || body.dig("result", "isError")).to be_truthy, name
      end
    end

    expect(all_rows).to eq(before)
  end
end
