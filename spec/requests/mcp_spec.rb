require "rails_helper"

RSpec.describe "MCP" do
  include_context "with MCP"

  it "initializes" do
    result = mcp_request("initialize", { protocolVersion: "2025-06-18", capabilities: {},
                                         clientInfo: { name: "spec", version: "1" } }, token: reader)["result"]

    expect(result.dig("serverInfo", "name")).to eq("chronicler")
    expect(response.media_type).to eq("application/json")
    expect(response.headers.to_h.keys.map(&:downcase)).not_to include("mcp-session-id", "set-cookie")
  end

  it "accepts notifications" do
    mcp_post({ jsonrpc: "2.0", method: "notifications/initialized" }, token: reader)

    expect(response).to have_http_status(:accepted)
  end

  it "marks the API's errors as errors" do
    result = call_tool("get_group", { id: 9 }, token: reader)["result"]

    expect(result).to include("isError" => true)
    expect(JSON.parse(result["content"].sole["text"])).to eq("error" => "Group not found")
    expect(call_tool("list_groups", {}, token: reader).dig("result", "isError")).to be_falsey
  end

  it "records the last use" do
    freeze_time do
      mcp_request("tools/list", token: reader)

      expect(TailnetMcp::Token.authenticate(reader).last_used_at).to eq(Time.current)
    end
  end

  it "does not use the API" do
    allow_any_instance_of(Api::BaseController).to receive(:authorize).and_raise("used the API") # rubocop:disable RSpec/AnyInstance
    allow(Net::HTTP).to receive(:start).and_raise("used HTTP")

    expect(JSON.parse(tool_text("list_groups", token: reader))).to eq([])
    expect(tool_text("get_summary", { characterIds: [1] }, token: reader)).to include("No characters found")
  end

  it "hides unexpected errors" do
    allow(GroupOperations).to receive(:list).and_raise(StandardError, "private detail")

    expect(JSON.parse(tool_text("list_groups", token: reader))).to eq("error" => "Internal server error")
  end
end
