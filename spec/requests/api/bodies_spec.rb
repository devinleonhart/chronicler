require "rails_helper"

RSpec.describe "API bodies" do
  def post_raw(text)
    post "/api/groups", params: text, headers: { "Content-Type" => "application/json" }
  end

  it "answers with plain JSON" do
    get "/api/groups"

    expect(response.headers["Content-Type"]).to eq("application/json")
  end

  it "fails on malformed JSON without an HTML page" do
    post_raw "{"

    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to eq('{"error":"Internal server error"}')
  end

  it "treats bodies that are not objects as empty" do
    ["", "null", "[]", "3", '"x"'].each do |text|
      post_raw text

      expect(response).to have_error("Group name is required")
    end
  end

  it "does not coerce types" do
    [1, true, ["x"], { "a" => 1 }].each do |name|
      send_json :post, "/api/groups", name: name

      expect(response).to have_error("Group name is required")
    end
  end

  it "fails on a name over 255 characters" do
    send_json :post, "/api/groups", name: "x" * 256

    expect(response).to have_http_status(:internal_server_error)
    expect(Group.count).to eq(0)
  end

  it "fails on a null bulk update" do
    send_json :put, "/api/characters/bulk", updates: [nil]

    expect(response).to have_http_status(:internal_server_error)
  end

  it "shows top-level and nested timestamps in their two forms" do
    group = create(:group, created_at: "2026-01-02 03:04:05.678")
    create(:character, groups: [group])
    get "/api/groups/#{group.id}"
    expect(json["createdAt"]).to eq("2026-01-02 03:04:05.678")
    get "/api/characters"
    expect(json.dig(0, "characterGroups", 0, "group", "createdAt")).to eq("2026-01-02T03:04:05.678")
  end
end
