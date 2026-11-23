require "rails_helper"

RSpec.describe "Browser" do
  it "loads a page in Chromium" do
    visit "/up"

    expect(page.status_code).to eq(200)
    expect(page.evaluate_script("navigator.userAgent")).to include("Chrome")
  end
end
