require "rails_helper"

RSpec.describe "Characters API" do
  let(:aria) { create(:character, name: "Aria", birth_date: "0400-03-15") }
  let(:heroes) { create(:group, name: "Heroes") }

  def bound_universe
    create(:universe_setting, start_date: "0100-01-01", end_date: "0900-12-31", current_day: "0500-01-01")
  end

  describe "GET /api/characters" do
    it "returns an empty array without characters" do
      get "/api/characters"

      expect(json).to eq([])
    end

    it "returns characters with groups" do
      aria
      get "/api/characters"

      expect(json).to contain_exactly(include("name" => "Aria", "characterGroups" => []))
    end

    it "filters by name, in any case and in part" do
      create(:character, name: "Aria the Bold")
      create(:character, name: "Bran the Wise")
      get "/api/characters?name=aria"

      expect(json.pluck("name")).to eq(["Aria the Bold"])
    end

    it "filters by groupId" do
      aria.groups << heroes
      create(:character)
      get "/api/characters?groupId=#{heroes.id}"

      expect(json.pluck("name")).to eq(["Aria"])
    end

    it "filters by birthYear" do
      create(:character, name: "Aria", birth_date: "1999-03-15")
      create(:character, name: "Bran", birth_date: "2001-05-01")
      get "/api/characters?birthYear=2001"

      expect(json.pluck("name")).to eq(["Bran"])
    end
  end

  describe "POST /api/characters" do
    it "creates a character" do
      send_json :post, "/api/characters", name: "Aria", birthDate: "0400-03-15"

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Aria", "birthDate" => "0400-03-15", "deathDate" => nil)
    end

    it "creates a character with groups" do
      send_json :post, "/api/characters", name: "Aria", birthDate: "0400-03-15", groupIds: [heroes.id]

      expect(response).to have_http_status(:created)
      expect(json["characterGroups"]).to contain_exactly(include("group" => include("name" => "Heroes")))
    end

    it "creates a character with a death date" do
      send_json :post, "/api/characters", name: "Fallen", birthDate: "0300-01-01", deathDate: "0450-12-31"

      expect(response).to have_http_status(:created)
      expect(json["deathDate"]).to eq("0450-12-31")
    end

    it "requires a name" do
      send_json :post, "/api/characters", birthDate: "0400-03-15"

      expect(response).to have_http_status(:bad_request)
    end

    it "requires a birthDate" do
      send_json :post, "/api/characters", name: "Aria"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an invalid birthDate format" do
      send_json :post, "/api/characters", name: "Aria", birthDate: "not-a-date"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a birthDate before the universe" do
      bound_universe
      send_json :post, "/api/characters", name: "Ancient", birthDate: "0050-03-15"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a birthDate after the universe" do
      bound_universe
      send_json :post, "/api/characters", name: "Future", birthDate: "1000-01-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a deathDate outside the universe" do
      bound_universe
      send_json :post, "/api/characters", name: "Fallen", birthDate: "0400-01-01", deathDate: "0950-12-31"

      expect(response).to have_http_status(:bad_request)
    end

    it "allows dates within the universe" do
      bound_universe
      send_json :post, "/api/characters", name: "Aria", birthDate: "0400-03-15"

      expect(response).to have_http_status(:created)
    end

    it "refuses unknown group ids and creates nothing" do
      [[heroes.id, 9999], ["x"], [nil], [99_999_999_999]].each do |ids|
        send_json :post, "/api/characters", name: "Aria", birthDate: "0400-03-15", groupIds: ids

        expect(response).to have_http_status(:bad_request)
        expect(json["error"]).to start_with("Groups not found: ")
      end
      expect(Character.count).to eq(0)
    end

    it "refuses impossible dates" do
      %w[2300-02-31 1500-02-29].each do |date|
        send_json :post, "/api/characters", name: "Aria", birthDate: date
        expect(response).to have_error("birthDate is required and must be a valid date string (YYYY-MM-DD)")

        send_json :post, "/api/characters", name: "Aria", birthDate: "0400-01-01", deathDate: date
        expect(response).to have_error("deathDate must be a valid date string (YYYY-MM-DD) or null")
      end
    end

    it "refuses a death before birth" do
      send_json :post, "/api/characters", name: "Aria", birthDate: "0400-01-02", deathDate: "0400-01-01"

      expect(response).to have_error("deathDate cannot be before birthDate")
    end
  end

  describe "GET /api/characters/:id" do
    it "returns a character" do
      get "/api/characters/#{aria.id}"

      expect(json["name"]).to eq("Aria")
    end

    it "returns 404 for a missing character" do
      get "/api/characters/9999"

      expect(response).to have_http_status(:not_found)
    end

    it "refuses an invalid id" do
      get "/api/characters/abc"

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PUT /api/characters/:id" do
    it "updates a character" do
      send_json :put, "/api/characters/#{aria.id}", name: "Aria Updated", deathDate: "0490-01-01"

      expect(response).to have_http_status(:ok)
      expect(json).to include("name" => "Aria Updated", "deathDate" => "0490-01-01")
    end

    it "updates group assignments" do
      send_json :put, "/api/characters/#{aria.id}", groupIds: [heroes.id]

      expect(json["characterGroups"].size).to eq(1)
    end

    it "returns 404 for a missing character" do
      send_json :put, "/api/characters/9999", name: "Ghost"

      expect(response).to have_http_status(:not_found)
    end

    it "refuses a birthDate outside the universe" do
      bound_universe
      send_json :put, "/api/characters/#{aria.id}", birthDate: "0050-01-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a deathDate outside the universe" do
      bound_universe
      send_json :put, "/api/characters/#{aria.id}", deathDate: "1000-01-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "checks dates before looking for the character" do
      bound_universe
      send_json :put, "/api/characters/9999", birthDate: "0050-01-01"

      expect(response).to have_error("birthDate cannot be before the universe start date (0100-01-01)")
    end

    it "rechecks a date that is sent again unchanged" do
      aria
      bound_universe.update!(start_date: "0401-01-01")
      send_json :put, "/api/characters/#{aria.id}", birthDate: "0400-03-15"
      expect(response).to have_http_status(:bad_request)

      send_json :put, "/api/characters/#{aria.id}", name: "Renamed"
      expect(response).to have_http_status(:ok)
    end

    it "refuses unknown group ids and changes nothing" do
      aria.groups << heroes
      before = all_rows
      send_json :put, "/api/characters/#{aria.id}", name: "Lost", groupIds: [9999]

      expect(response).to have_error("Groups not found: 9999")
      expect(all_rows).to eq(before)
    end

    it "refuses a death before birth when only one is sent" do
      aria.update!(death_date: "0450-01-01")

      send_json :put, "/api/characters/#{aria.id}", deathDate: "0400-03-14"
      expect(response).to have_error("deathDate cannot be before birthDate")
      send_json :put, "/api/characters/#{aria.id}", birthDate: "0450-01-02"
      expect(response).to have_error("deathDate cannot be before birthDate")
    end

    it "advances updatedAt without other changes" do
      aria.update!(updated_at: 1.day.ago)
      expect { send_json :put, "/api/characters/#{aria.id}", {} }.to(change { aria.reload.updated_at })
    end
  end

  describe "DELETE /api/characters/:id" do
    it "deletes a character" do
      delete "/api/characters/#{aria.id}"

      expect(response).to have_http_status(:no_content)
      expect(Character).not_to exist(aria.id)
    end

    it "returns 404 for a missing character" do
      delete "/api/characters/9999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/characters/placeholders" do
    it "returns characters with the default date" do
      create(:character, name: "Placeholder", birth_date: "2200-01-01")
      aria
      get "/api/characters/placeholders"

      expect(json.pluck("name")).to eq(["Placeholder"])
    end

    it "returns characters with another date" do
      create(:character, name: "Placeholder", birth_date: "1111-01-01")
      aria
      get "/api/characters/placeholders?birthDate=1111-01-01"

      expect(json.pluck("name")).to eq(["Placeholder"])
    end

    it "returns an empty array without placeholders" do
      aria
      get "/api/characters/placeholders"

      expect(json).to eq([])
    end
  end

  describe "POST /api/characters/:id/groups" do
    it "adds a group" do
      send_json :post, "/api/characters/#{aria.id}/groups", groupId: heroes.id

      expect(response).to have_http_status(:ok)
      expect(json["characterGroups"]).to contain_exactly(include("group" => include("name" => "Heroes")))
    end

    it "adds a group only once" do
      2.times { send_json :post, "/api/characters/#{aria.id}/groups", groupId: heroes.id }

      expect(response).to have_http_status(:ok)
      expect(json["characterGroups"].size).to eq(1)
    end

    it "returns 404 for a missing character" do
      send_json :post, "/api/characters/9999/groups", groupId: heroes.id

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a missing group" do
      send_json :post, "/api/characters/#{aria.id}/groups", groupId: 9999

      expect(response).to have_http_status(:not_found)
    end

    it "refuses an invalid groupId" do
      send_json :post, "/api/characters/#{aria.id}/groups", groupId: "bad"

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /api/characters/:id/groups/:groupId" do
    it "removes a group" do
      aria.groups << heroes
      delete "/api/characters/#{aria.id}/groups/#{heroes.id}"

      expect(response).to have_http_status(:ok)
      expect(json["characterGroups"]).to be_empty
    end

    it "returns 404 for a missing character" do
      delete "/api/characters/9999/groups/1"

      expect(response).to have_http_status(:not_found)
    end

    it "refuses an invalid character id" do
      delete "/api/characters/abc/groups/1"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an invalid group id" do
      delete "/api/characters/#{aria.id}/groups/abc"

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PUT /api/characters/bulk" do
    let(:bran) { create(:character, name: "Bran", birth_date: "0410-05-01") }

    def bulk(*updates)
      send_json :put, "/api/characters/bulk", updates:
    end

    it "updates several characters" do
      bulk({ id: aria.id, name: "Aria Updated" }, { id: bran.id, name: "Bran Updated" })

      expect(response).to have_http_status(:ok)
      expect(json.pluck("name")).to eq(["Aria Updated", "Bran Updated"])
    end

    it "updates group assignments" do
      bulk({ id: aria.id, groupIds: [heroes.id] })

      expect(json.first["characterGroups"].size).to eq(1)
    end

    it "refuses empty updates" do
      bulk

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses missing updates" do
      send_json :put, "/api/characters/bulk", {}

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 404 if any character is missing" do
      bulk({ id: aria.id, name: "OK" }, { id: 9999, name: "Ghost" })

      expect(response).to have_http_status(:not_found)
    end

    it "refuses an invalid birthDate format" do
      bulk({ id: aria.id, birthDate: "not-a-date" })

      expect(response).to have_http_status(:bad_request)
    end

    it "changes nothing when the last entry is invalid" do
      aria.groups << heroes
      last = {
        { birthDate: "0410-02-30" } => "birthDate must be YYYY-MM-DD",
        { deathDate: "0409-01-01" } => "deathDate cannot be before birthDate",
        { groupIds: [9999] } => "Groups not found: 9999",
        { name: "" } => "name must be a non-empty string"
      }
      bran
      before = all_rows

      last.each do |fields, message|
        bulk({ id: aria.id, name: "Lost", groupIds: [] }, { id: bran.id }.merge(fields))

        expect(response).to have_error("Character #{bran.id}: #{message}")
        expect(all_rows).to eq(before)
      end
    end

    it "checks each entry for the same character" do
      bulk({ id: aria.id, birthDate: "0400-02-31" }, { id: aria.id, birthDate: "0400-02-01" })

      expect(response).to have_error("Character #{aria.id}: birthDate must be YYYY-MM-DD")
    end
  end

  describe "GET /api/characters/:id/events" do
    it "returns events by startDate" do
      late = create(:event, name: "Late Battle", start_date: "0500-06-01")
      early = create(:event, name: "Early Battle", start_date: "0450-01-01")
      aria.events << [late, early]
      get "/api/characters/#{aria.id}/events"

      expect(json.pluck("name")).to eq(["Early Battle", "Late Battle"])
    end

    it "returns an empty array without events" do
      get "/api/characters/#{aria.id}/events"

      expect(json).to eq([])
    end

    it "returns 404 for a missing character" do
      get "/api/characters/9999/events"

      expect(response).to have_http_status(:not_found)
    end

    it "refuses an invalid id" do
      get "/api/characters/abc/events"

      expect(response).to have_http_status(:bad_request)
    end
  end
end
