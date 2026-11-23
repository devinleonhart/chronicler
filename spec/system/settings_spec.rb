require "rails_helper"

RSpec.describe "Settings" do
  let!(:event) { create(:event, name: "Today", start_date: "2300-09-25", is_current_day: true) }

  before do
    create(:universe_setting)
    sign_in
    click_on "Settings"
  end

  it "shows the settings" do
    expect(page).to have_field("Universe Name", with: "Knighthood")
    expect(page).to have_field("Universe Start Date", with: "1000-01-01")
    expect(page).to have_field("Universe End Date", with: "2320-12-31")
    expect(page).to have_field("Current Day", with: "2300-09-25")
  end

  it "saves and moves the Current Day event" do
    fill_in "Universe Name", with: "Renamed"
    fill_in "Current Day", with: "2301-01-02"
    click_on "Save Settings"

    expect(page).to have_css(".bb-alert-success", text: "Settings saved")
    expect(page).to have_field("Universe Name", with: "Renamed")
    expect(event.reload.start_date).to eq("2301-01-02")
  end

  it "shows an invalid date's message and keeps the input" do
    fill_in "Universe Name", with: "Kept"
    fill_in "Current Day", with: "2300-02-31"
    click_on "Save Settings"

    expect(page).to have_text("Current day must be a real date (YYYY-MM-DD)")
    expect(page).to have_field("Current Day", with: "2300-02-31")
    expect(page).to have_field("Universe Name", with: "Kept")
    expect(event.reload.start_date).to eq("2300-09-25")
  end
end
