require "rails_helper"

RSpec.describe "Events API" do
  let(:battle) { create(:event, name: "The Battle", start_date: "0450-06-01") }
  let(:aria) { create(:character, name: "Aria", birth_date: "0400-03-15") }
  let(:unborn) { create(:character, name: "Lyra", birth_date: "0500-01-01") }
  let(:dead) { create(:character, name: "Old Mage", birth_date: "0300-01-01", death_date: "0400-12-31") }

  def bound_universe
    create(:universe_setting, start_date: "0100-01-01", end_date: "0900-12-31", current_day: "0500-01-01")
  end

  describe "GET /api/events" do
    it "returns an empty array without events" do
      get "/api/events"

      expect(json).to eq([])
    end

    it "returns events with characters" do
      battle
      get "/api/events"

      expect(json).to contain_exactly(include("name" => "The Battle", "eventCharacters" => []))
    end

    it "sorts by startDate, then id" do
      late = create(:event, start_date: "0500-06-15")
      early = create(:event, start_date: "0100-01-01")
      tied = create(:event, start_date: "0500-06-15")
      late.update!(name: "Moved")
      get "/api/events"

      expect(json.pluck("id")).to eq([early, late, tied].map(&:id))
    end

    it "filters by name, in any case and in part" do
      battle
      create(:event, name: "The Council")
      get "/api/events?name=battle"

      expect(json.pluck("name")).to eq(["The Battle"])
    end

    it "filters by characterId" do
      battle.characters << aria
      create(:event)
      get "/api/events?characterId=#{aria.id}"

      expect(json.pluck("name")).to eq(["The Battle"])
    end

    it "filters by startAfter" do
      create(:event, name: "Early", start_date: "0400-01-01")
      create(:event, name: "Late", start_date: "0500-01-01")
      get "/api/events?startAfter=0450-01-01"

      expect(json.pluck("name")).to eq(["Late"])
    end

    it "filters by startBefore" do
      create(:event, name: "Early", start_date: "0400-01-01")
      create(:event, name: "Late", start_date: "0500-01-01")
      get "/api/events?startBefore=0450-01-01"

      expect(json.pluck("name")).to eq(["Early"])
    end
  end

  describe "POST /api/events" do
    def create_event(fields = {})
      send_json :post, "/api/events", { name: "The Battle", startDate: "0450-06-01" }.merge(fields)
    end

    it "creates an event" do
      create_event

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "The Battle", "startDate" => "0450-06-01",
                              "endDate" => nil, "isCurrentDay" => false)
    end

    it "creates an event with characters" do
      create_event characterIds: [aria.id]

      expect(response).to have_http_status(:created)
      expect(json["eventCharacters"]).to contain_exactly(include("character" => include("name" => "Aria")))
    end

    it "creates an event with an end date" do
      create_event endDate: "0455-12-31"

      expect(response).to have_http_status(:created)
      expect(json["endDate"]).to eq("0455-12-31")
    end

    it "requires a name" do
      send_json :post, "/api/events", startDate: "0450-06-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "requires a startDate" do
      send_json :post, "/api/events", name: "The Battle"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a startDate before the universe" do
      bound_universe
      create_event startDate: "0050-06-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a startDate after the universe" do
      bound_universe
      create_event startDate: "1000-01-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an endDate outside the universe" do
      bound_universe
      create_event startDate: "0800-01-01", endDate: "0950-12-31"

      expect(response).to have_http_status(:bad_request)
    end

    it "allows dates within the universe" do
      bound_universe
      create_event

      expect(response).to have_http_status(:created)
    end

    it "refuses a character not yet born when it ended" do
      create_event startDate: "0450-01-01", endDate: "0455-12-31", characterIds: [unborn.id]

      expect(response).to have_http_status(:bad_request)
      expect(Event.count).to eq(0)
    end

    it "refuses a character already dead when it started" do
      create_event characterIds: [dead.id]

      expect(response).to have_http_status(:bad_request)
    end

    it "allows a character born during it" do
      young = create(:character, birth_date: "0455-06-01")
      create_event startDate: "0450-01-01", endDate: "0460-12-31", characterIds: [young.id]

      expect(response).to have_http_status(:created)
    end

    it "allows a character who dies during it" do
      fallen = create(:character, birth_date: "0400-01-01", death_date: "0455-06-01")
      create_event startDate: "0450-01-01", endDate: "0460-12-31", characterIds: [fallen.id]

      expect(response).to have_http_status(:created)
    end

    it "refuses unknown character ids and creates nothing" do
      create_event characterIds: [aria.id, 9999]

      expect(response).to have_error("Characters not found: 9999")
      expect(Event.count).to eq(0)
    end

    it "refuses impossible dates" do
      create_event startDate: "0450-02-30"
      expect(response).to have_error("startDate is required and must be a valid date string (YYYY-MM-DD)")
      create_event endDate: "0450-02-30"
      expect(response).to have_error("endDate must be a valid date string (YYYY-MM-DD) or null")
    end

    it "refuses an end before its start" do
      create_event endDate: "0450-05-31"

      expect(response).to have_error("endDate cannot be before startDate")
    end
  end

  describe "GET /api/events/:id" do
    it "returns an event" do
      get "/api/events/#{battle.id}"

      expect(json["name"]).to eq("The Battle")
    end

    it "returns 404 for a missing event" do
      get "/api/events/9999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/events/:id" do
    def update_battle(fields)
      send_json :put, "/api/events/#{battle.id}", fields
    end

    it "updates an event" do
      update_battle name: "The Great Battle", endDate: "0450-06-15"

      expect(response).to have_http_status(:ok)
      expect(json).to include("name" => "The Great Battle", "endDate" => "0450-06-15")
    end

    it "updates character assignments" do
      update_battle characterIds: [aria.id]

      expect(json["eventCharacters"].size).to eq(1)
    end

    it "returns 404 for a missing event" do
      send_json :put, "/api/events/9999", name: "Ghost Event"

      expect(response).to have_http_status(:not_found)
    end

    it "refuses a startDate outside the universe" do
      bound_universe
      update_battle startDate: "0050-01-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an endDate outside the universe" do
      bound_universe
      update_battle endDate: "1000-01-01"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a character not yet born" do
      update_battle characterIds: [unborn.id]

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a character already dead" do
      update_battle characterIds: [dead.id]

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a new startDate that leaves a member unborn" do
      battle.characters << aria
      before = all_rows
      update_battle startDate: "0399-01-01"

      expect(response).to have_error('Character "Aria" was not yet born when this event ended ' \
                                     "(born 0400-03-15, event ends 0399-01-01)")
      expect(all_rows).to eq(before)
    end

    it "lets an event already in violation be renamed" do
      EventCharacter.create!(event: battle, character: dead)

      update_battle name: "Renamed"
      expect(response).to have_http_status(:ok)
      update_battle name: "Again", startDate: "0450-06-01", endDate: nil, characterIds: [dead.id]
      expect(response).to have_http_status(:ok)
      expect(json["name"]).to eq("Again")
    end

    it "refuses unknown character ids and changes nothing" do
      battle.characters << aria
      before = all_rows
      update_battle name: "Lost", characterIds: [9999, 8888]

      expect(response).to have_error("Characters not found: 9999, 8888")
      expect(all_rows).to eq(before)
    end

    it "refuses an end before its start when only one is sent" do
      battle.update!(end_date: "0451-01-01")

      update_battle endDate: "0450-05-31"
      expect(response).to have_error("endDate cannot be before startDate")
      update_battle startDate: "0451-01-02"
      expect(response).to have_error("endDate cannot be before startDate")
    end
  end

  describe "DELETE /api/events/:id" do
    it "deletes an event" do
      delete "/api/events/#{battle.id}"

      expect(response).to have_http_status(:no_content)
      expect(Event).not_to exist(battle.id)
    end

    it "refuses to delete the Current Day event" do
      event = create(:event, is_current_day: true)
      delete "/api/events/#{event.id}"

      expect(response).to have_error("Cannot delete the Current Day event")
      expect(Event).to exist(event.id)
    end

    it "returns 404 for a missing event" do
      delete "/api/events/9999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/events/:id/characters" do
    def add(character_id)
      send_json :post, "/api/events/#{battle.id}/characters", characterId: character_id
    end

    it "adds a character" do
      add aria.id

      expect(response).to have_http_status(:ok)
      expect(json["eventCharacters"]).to contain_exactly(include("character" => include("name" => "Aria")))
    end

    it "adds a character only once" do
      2.times { add aria.id }

      expect(response).to have_http_status(:ok)
      expect(json["eventCharacters"].size).to eq(1)
    end

    it "returns 404 for a missing event" do
      send_json :post, "/api/events/9999/characters", characterId: aria.id

      expect(response).to have_http_status(:not_found)
    end

    it "refuses an invalid characterId" do
      add "bad"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a character not yet born" do
      add unborn.id

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses a character already dead" do
      add dead.id

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an unknown character" do
      [9999, 99_999_999_999].each do |id|
        add id

        expect(response).to have_error("Characters not found: #{id}")
      end
    end
  end

  describe "DELETE /api/events/:id/characters/:characterId" do
    it "removes a character" do
      battle.characters << aria
      delete "/api/events/#{battle.id}/characters/#{aria.id}"

      expect(response).to have_http_status(:ok)
      expect(json["eventCharacters"]).to be_empty
    end

    it "returns 404 for a missing event" do
      delete "/api/events/9999/characters/1"

      expect(response).to have_http_status(:not_found)
    end

    it "refuses an invalid event id" do
      delete "/api/events/abc/characters/1"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses an invalid character id" do
      delete "/api/events/#{battle.id}/characters/abc"

      expect(response).to have_http_status(:bad_request)
    end
  end
end
