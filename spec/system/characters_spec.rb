require "rails_helper"

RSpec.describe "Characters" do
  before do
    create(:universe_setting)
    heroes = create(:group, name: "Heroes")
    create(:group, name: "Scouts")
    create(:character, name: "Aria", birth_date: "2270-05-10", groups: [heroes])
    create(:character, name: "Bran", birth_date: "2250-01-01", death_date: "2290-02-03")
    sign_in
    click_on "Characters"
  end

  def row(name)
    find("tr", text: name)
  end

  it "lists characters" do
    expect(page).to have_css(".bb-subtitle", exact_text: "2 characters")
    expect(row("Aria")).to have_text("2270-05-10").and have_text("Heroes")
    expect(row("Bran")).to have_text("2290-02-03")
  end

  it "creates a character with groups" do
    click_on "Add Character"
    within("dialog[open]") do
      expect(page).to have_text("1000-01-01 to 2320-12-31")
      fill_in "Name", with: " Cora "
      fill_in "Birth Date", with: "2280-03-04"
      check "Heroes"
      check "Scouts"
      click_on "Add Character"
    end

    expect(page).to have_css(".bb-alert-success", text: "Character added successfully")
    expect(row("Cora")).to have_text("2280-03-04").and have_text("Heroes").and have_text("Scouts")
  end

  it "edits a character" do
    click_on "Edit Aria"
    within("dialog[open]") do
      expect(page).to have_checked_field("Heroes")
      fill_in "Name", with: "Aria II"
      fill_in "Death Date (optional)", with: "2299-01-01"
      uncheck "Heroes"
      check "Scouts"
      click_on "Save Changes"
    end

    expect(page).to have_css(".bb-alert-success", text: "Character updated successfully")
    expect(row("Aria II")).to have_text("2299-01-01").and have_text("Scouts").and have_no_text("Heroes")
  end

  it "clears the death date" do
    click_on "Edit Bran"
    within("dialog[open]") do
      fill_in "Death Date (optional)", with: ""
      click_on "Save Changes"
    end

    expect(page).to have_css(".bb-alert-success")
    expect(Character.find_by!(name: "Bran").death_date).to be_nil
  end

  it "shows errors and keeps the input" do
    click_on "Edit Aria"
    within("dialog[open]") do
      fill_in "Death Date (optional)", with: "2260-01-01"
      check "Scouts"
      click_on "Save Changes"
      expect(page).to have_text("Death date cannot be before the birth date")
      expect(page).to have_field("Death Date (optional)", with: "2260-01-01")
      expect(page).to have_checked_field("Scouts")

      fill_in "Death Date (optional)", with: "2321-01-01"
      click_on "Save Changes"
      expect(page).to have_text("Death date cannot be after the universe end date (2320-12-31)")
    end
    expect(Character.find_by!(name: "Aria").groups.map(&:name)).to eq(["Heroes"])
  end

  it "searches by name and group" do
    fill_in "Search characters", with: "BRA"
    expect(page).to have_no_css("tr", text: "Aria")
    expect(page).to have_css("tr", text: "Bran")
    fill_in "Search characters", with: "heroes"
    expect(page).to have_css("tr", text: "Aria")
    expect(page).to have_no_css("tr", text: "Bran")
    fill_in "Search characters", with: "nobody"
    expect(page).to have_text('No characters match "nobody"')
  end

  it "deletes after confirmation only" do
    click_on "Delete Aria"
    within("dialog[open]") { click_on "Cancel" }
    expect(page).to have_no_css("dialog[open]")
    click_on "Delete Aria"
    within("dialog[open]") do
      expect(page).to have_text("This will remove them from all events.")
      click_on "Delete"
    end

    expect(page).to have_css(".bb-alert-success", text: "Character deleted")
    expect(page).to have_no_css("tr", text: "Aria")
  end
end
