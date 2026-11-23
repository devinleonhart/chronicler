require "rails_helper"

RSpec.describe "Groups API" do
  describe "GET /api/groups" do
    it "returns an empty array without groups" do
      get "/api/groups"

      expect(json).to eq([])
    end

    it "returns groups with characters" do
      create(:group, name: "Heroes", description: "The good guys")
      get "/api/groups"

      expect(json).to contain_exactly(include("name" => "Heroes", "characterGroups" => []))
    end

    it "sorts members by id" do
      group = create(:group)
      ids = create_list(:character, 3).map(&:id)
      ids.reverse_each { |id| CharacterGroup.create!(character_id: id, group_id: group.id) }
      get "/api/groups"

      expect(json.first["characterGroups"].pluck("characterId")).to eq(ids)
    end
  end

  describe "POST /api/groups" do
    it "creates a group" do
      send_json :post, "/api/groups", name: "Heroes", description: "Brave adventurers"

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Heroes", "description" => "Brave adventurers")
    end

    it "creates a group without description" do
      send_json :post, "/api/groups", name: "Villains"

      expect(response).to have_http_status(:created)
      expect(json["description"]).to be_nil
    end

    it "requires a name" do
      send_json :post, "/api/groups", description: "No name"

      expect(response).to have_error("Group name is required")
    end
  end

  describe "GET /api/groups/:id" do
    it "returns a group" do
      get "/api/groups/#{create(:group, name: 'Heroes').id}"

      expect(json["name"]).to eq("Heroes")
    end

    it "returns 404 for a missing group" do
      get "/api/groups/9999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/groups/:id" do
    it "updates a group" do
      group = create(:group)
      send_json :put, "/api/groups/#{group.id}", name: "Updated Heroes", description: "Even braver"

      expect(response).to have_http_status(:ok)
      expect(json).to include("name" => "Updated Heroes", "description" => "Even braver")
    end

    it "returns 404 for a missing group" do
      send_json :put, "/api/groups/9999", name: "Ghost"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/groups/:id" do
    it "deletes a group" do
      group = create(:group)
      delete "/api/groups/#{group.id}"

      expect(response).to have_http_status(:no_content)
      expect(Group).not_to exist(group.id)
    end

    it "returns 404 for a missing group" do
      delete "/api/groups/9999"

      expect(response).to have_http_status(:not_found)
    end
  end
end
