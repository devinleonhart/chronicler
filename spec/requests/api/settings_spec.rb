require "rails_helper"

RSpec.describe "Settings API" do
  def create_settings
    create(:universe_setting, start_date: "0100-01-01", end_date: "0900-12-31", current_day: "0500-06-15")
  end

  describe "GET /api/settings" do
    it "creates settings and the Current Day event if none exist" do
      get "/api/settings"

      expect(response).to have_http_status(:ok)
      expect(json).to include("name" => "My Universe", "startDate" => "0001-01-01", "currentDay" => "0500-06-15")
      expect(Event.find_by(is_current_day: true)).to have_attributes(name: "Current Day", start_date: "0500-06-15")
    end

    it "returns existing settings" do
      create_settings
      get "/api/settings"

      expect(json).to include("startDate" => "0100-01-01", "currentDay" => "0500-06-15")
    end
  end

  describe "PUT /api/settings" do
    before { create_settings }

    it "updates settings" do
      send_json :put, "/api/settings", name: "New Name", currentDay: "0600-01-01"

      expect(response).to have_http_status(:ok)
      expect(json).to include("name" => "New Name", "currentDay" => "0600-01-01")
    end

    it "moves the Current Day event" do
      event = create(:event, start_date: "0500-06-15", is_current_day: true)
      send_json :put, "/api/settings", currentDay: "0600-01-01"

      expect(event.reload.start_date).to eq("0600-01-01")
    end

    it "moves the Current Day event when the same day is sent again" do
      event = create(:event, start_date: "0700-01-01", is_current_day: true)
      send_json :put, "/api/settings", name: "Other"
      expect(event.reload.start_date).to eq("0700-01-01")
      send_json :put, "/api/settings", currentDay: "0500-06-15"
      expect(event.reload.start_date).to eq("0500-06-15")
    end

    it "refuses an invalid date format" do
      send_json :put, "/api/settings", currentDay: "not-a-date"

      expect(response).to have_http_status(:bad_request)
    end

    it "refuses impossible dates" do
      %w[startDate endDate currentDay].each do |field|
        send_json :put, "/api/settings", field => "2300-02-31"

        expect(response).to have_error("#{field} must be a valid date string (YYYY-MM-DD)")
      end
    end

    it "changes nothing when the Current Day event cannot be moved" do
      create(:event, start_date: "0500-06-15", is_current_day: true)
      before = all_rows
      allow(Event).to receive(:where).and_call_original
      allow(Event).to receive(:where).with(is_current_day: true).and_raise(ActiveRecord::StatementInvalid)

      send_json :put, "/api/settings", name: "Lost", currentDay: "0600-01-01"

      expect(response).to have_http_status(:internal_server_error)
      expect(json).to eq("error" => "Internal server error")
      expect(all_rows).to eq(before)
    end
  end
end
