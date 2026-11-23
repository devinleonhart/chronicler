require "rails_helper"

RSpec.describe "Events pages" do
  let!(:event) { create(:event, name: "Battle", characters: [character]) }
  let(:character) { create(:character) }

  context "when signed in" do
    before { sign_in }

    it "returns 422 for an invalid form" do
      post events_path, params: { event: { name: "", start_date: "2290-01-01" } }
      expect(response).to have_http_status(:unprocessable_content)
      [{ start_date: "2269-01-01" }, { end_date: "2280-01-01" }, { start_date: "x" }, { character_ids: ["", "9999"] }]
        .each do |fields|
          patch event_path(event), params: { event: fields }
          expect(response).to have_http_status(:unprocessable_content)
        end

      expect(Event.sole).to have_attributes(start_date: "2290-01-01", end_date: nil, characters: [character])
    end

    it "does not delete the Current Day event" do
      current = create(:event, is_current_day: true)
      delete event_path(current)

      expect(response).to redirect_to(events_path)
      expect(flash[:error]).to eq("The Current Day event cannot be deleted")
      expect(Event).to exist(current.id)
    end

    it "ignores fields outside the form" do
      patch event_path(event), params: { event: { name: "Renamed", is_current_day: true } }

      expect(event.reload).to have_attributes(name: "Renamed", is_current_day: false)
    end

    it "accepts any filter values" do
      get events_path(q: "%", sort: "bad", dir: "bad", view: "bad", births: "x", group_ids: ["x", "99999999999"])
      expect(response).to have_http_status(:ok)
      get "/events?group_ids=3&q[]=a&sort[a]=b"

      expect(response).to have_http_status(:ok)
    end
  end

  it "refuses a write without a CSRF token" do
    sign_in
    with_forgery_protection { delete event_path(event) }

    expect(response).to have_http_status(:unprocessable_content)
    expect(Event).to exist(event.id)
  end
end
