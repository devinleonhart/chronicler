require "rails_helper"

RSpec.describe "Signing in" do
  it "signs in, navigates and signs out" do
    sign_in
    expect(page).to have_current_path("/events")
    expect(page).to have_css("h1", text: "Events")

    within("#navbar_desktop") { click_on "Current Day" }
    expect(page).to have_css("h1", text: "Current Day")
    expect(page.evaluate_script("typeof window.Stimulus")).to eq("object")

    click_on "Sign Out"
    expect(page).to have_current_path(new_session_path)
    expect(page).to have_no_button("Sign Out")
  end

  it "shows a dismissible message for a wrong password" do
    create(:user)
    visit new_session_path
    fill_in "Email", with: "owner@example.com"
    fill_in "Password", with: "wrong"
    click_on "Sign In"

    expect(page).to have_css(".bb-alert-error", text: "Try another email address or password.")
    click_on "Dismiss"
    expect(page).to have_no_css(".bb-alert-error")
  end

  it "opens the menu on a narrow screen" do
    sign_in
    page.current_window.resize_to(400, 800)
    expect(page).to have_no_link("Groups")
    click_on "Open main menu"
    click_on "Groups"

    expect(page).to have_css("h1", text: "Groups")
  end
end
