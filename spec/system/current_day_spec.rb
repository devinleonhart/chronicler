require "rails_helper"

RSpec.describe "Current Day" do
  before do
    create(:universe_setting, current_day: "2300-09-25")
    heroes = create(:group, name: "Heroes")
    scouts = create(:group, name: "Scouts")
    create(:group, name: "Empty")
    create(:character, name: "Aria", birth_date: "2270-09-25", groups: [heroes, scouts])
    create(:character, name: "Bran", birth_date: "2270-09-26")
    create(:character, name: "Cora", birth_date: "2250-01-01", death_date: "2290-02-03", groups: [heroes])
    create(:character, name: "Dana", birth_date: "2300-09-25", death_date: "2300-09-25")
    sign_in
    click_on "Current Day"
  end

  def section(title)
    find("section section", text: title)
  end

  def cards(title)
    section(title).all("a").map { |card| card.text.squish }
  end

  it "shows the living and the deceased with ages and counts" do
    expect(page).to have_text("2300-09-25")
    expect(cards("Living (3)")).to eq(["Aria 30", "Bran 29", "Dana 0"])
    expect(cards("Deceased (1)")).to eq(["Cora 40 at death"])
  end

  it "shows characters under each of their groups" do
    click_on "By Group"

    expect(page).to have_css("h2", text: "Heroes")
    expect(page).to have_current_path(/view=group/)
    expect(all("section section h2").map(&:text)).to eq(%w[Heroes Scouts Ungrouped])
    expect(cards("Heroes")).to eq(["Aria 30", "Cora 40 at death"])
    expect(cards("Scouts")).to eq(["Aria 30"])
    expect(cards("Ungrouped")).to eq(["Bran 29", "Dana 0"])

    click_on "All"
    expect(page).to have_css("h2", text: "Living (3)")
  end

  it "edits from a card and stays in the view" do
    click_on "By Group"
    within(section("Scouts")) { click_on "Aria" }
    within("dialog[open]") do
      expect(page).to have_css("h2", text: "Edit Character")
      fill_in "Birth Date", with: "2280-01-01"
      click_on "Save Changes"
    end

    expect(page).to have_css(".bb-alert-success", text: "Character updated successfully")
    expect(cards("Scouts")).to eq(["Aria 20"])
    expect(page).to have_current_path(/view=group/)
  end
end
