require "rails_helper"

RSpec.describe "Settings page" do
  let!(:setting) { create(:universe_setting) }

  it "creates the settings on first sight" do
    setting.destroy!
    sign_in
    get settings_path

    expect(UniverseSetting.sole.name).to eq("My Universe")
    expect(Event.sole).to have_attributes(is_current_day: true)
  end

  it "returns 422 for an invalid form" do
    sign_in
    [{ name: " " }, { start_date: "2300-02-31" }, { end_date: "" }, { current_day: "soon" }].each do |fields|
      patch settings_path, params: { universe_setting: fields }
      expect(response).to have_http_status(:unprocessable_content)
    end

    expect(setting.reload.updated_at).to eq(setting.updated_at)
  end

  it "keeps the current day within the universe" do
    sign_in
    %w[0999-12-31 2321-01-01].each do |date|
      patch settings_path, params: { universe_setting: { current_day: date } }
      expect(response).to have_http_status(:unprocessable_content)
    end
    patch settings_path, params: { universe_setting: { current_day: "2320-12-31" } }

    expect(response).to redirect_to(settings_path)
  end

  it "refuses a write when signed out" do
    patch settings_path, params: { universe_setting: { name: "New" } }

    expect(response).to redirect_to(new_session_path)
    expect(setting.reload.name).to eq("Knighthood")
  end

  it "refuses a write without a CSRF token" do
    sign_in
    with_forgery_protection { patch settings_path, params: { universe_setting: { name: "New" } } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(setting.reload.name).to eq("Knighthood")
  end
end
