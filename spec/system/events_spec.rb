require "rails_helper"

RSpec.describe "Events" do
  let(:heroes) { create(:group, name: "Heroes") }
  let(:scouts) { create(:group, name: "Scouts") }
  let!(:aria) { create(:character, name: "Aria", birth_date: "2270-05-10", groups: [heroes]) }
  let!(:bran) { create(:character, name: "Bran", birth_date: "2250-01-01", death_date: "2292-02-03", groups: [scouts]) }

  before do
    create(:universe_setting)
    create(:event, name: "War", start_date: "2291-01-01", end_date: "2293-06-01", characters: [bran, aria])
    create(:event, name: "Feast", start_date: "2295-01-01", characters: [aria])
    create(:event, name: "Omen", start_date: "2280-01-01", end_date: "2280-01-01")
    create(:event, name: "Today", start_date: "2300-09-25", is_current_day: true)
    sign_in
  end

  def names
    all("tbody tr td:first-child").map { |cell| cell.text.squish }
  end

  def row(name)
    find("tbody tr", text: /\A#{name}\b/)
  end

  it "lists events by start date under the universe's name" do
    expect(page).to have_css(".bb-subtitle", exact_text: "Knighthood")
    expect(names).to eq(%w[Omen War Feast Today])
  end

  it "shows ages, with a range for spans and the dead struck through" do
    cells = row("War").all("li").map { |item| item.text.squish }
    expect(cells).to eq(["Aria age 20 → 23", "Bran age 41 → 42 (deceased)"])
    expect(row("Feast").find("li")).to have_text("Aria age 24")
    expect(page).to have_no_css("s")

    create(:event, name: "Wake", start_date: "2292-02-03", characters: [bran])
    visit events_path
    expect(row("Wake")).to have_css("s", text: "Bran")
    expect(row("Wake")).to have_text("age 42")
  end

  it "searches by event name and by character name" do
    fill_in "Search events", with: "WA"
    expect(page).to have_no_css("tr", text: "Omen")
    expect(names).to eq(["War"])
    fill_in "Search events", with: "aria"
    expect(page).to have_css("tr", text: "Feast")
    expect(names).to eq(%w[War Feast])
    expect(page).to have_current_path(/q=aria/)
    fill_in "Search events", with: "nothing"
    expect(page).to have_text("No events match the current filters.")
  end

  it "filters by groups, keeping the Current Day" do
    check "Scouts", allow_label_click: true
    expect(page).to have_no_css("tr", text: "Feast")
    expect(names).to eq(%w[War Today])
    check "Heroes", allow_label_click: true
    expect(page).to have_css("tr", text: "Feast")
    expect(names).to eq(%w[War Feast Today])

    visit current_url
    expect(page).to have_checked_field("Scouts", visible: :all)
    expect(names).to eq(%w[War Feast Today])
  end

  it "clears filters" do
    expect(page).to have_no_link("Clear filters")
    check "Scouts", allow_label_click: true
    fill_in "Search events", with: "war"
    expect(page).to have_no_css("tr", text: "Today")
    click_on "Clear filters"

    expect(page).to have_css("tr", text: "Omen")
    expect(names.size).to eq(4)
    expect(page).to have_field("Search events", with: "")
    expect(page).to have_unchecked_field("Scouts", visible: :all)
  end

  it "shows births and deaths, filtered like events" do
    check "Births & Deaths", allow_label_click: true
    expect(page).to have_css("tr", text: "Aria born")
    expect(names).to eq(["Bran born", "Aria born", "Omen", "War", "Bran died", "Feast", "Today"])
    expect(row("Bran died")).to have_no_button.and have_no_link

    check "Heroes", allow_label_click: true
    expect(page).to have_no_css("tr", text: "Bran born")
    expect(names).to eq(["Aria born", "War", "Feast", "Today"])
    fill_in "Search events", with: "aria"
    expect(page).to have_no_css("tr", text: "Today")
    expect(names).to eq(["Aria born", "War", "Feast"])
  end

  it "sorts by each column in both directions" do
    { "Event" => %w[Feast Omen Today War], "Start Date" => %w[Omen War Feast Today],
      "End Date" => %w[Feast Today Omen War] }.each do |column, ascending|
      click_on column
      expect(page).to have_css("th[aria-sort=ascending]", text: column)
      expect(names).to eq(ascending)
      click_on column
      expect(page).to have_css("th[aria-sort=descending]", text: column)
      expect(names.grep(/Omen|War/)).to eq(ascending.grep(/Omen|War/).reverse)
    end
  end

  it "keeps the sort while filtering, and the filter while sorting" do
    click_on "Event"
    expect(page).to have_css("th[aria-sort=ascending]", text: "Event")
    check "Heroes", allow_label_click: true
    expect(page).to have_no_css("tr", text: "Omen")
    expect(names).to eq(%w[Feast Today War])
    click_on "Event"
    expect(page).to have_css("th[aria-sort=descending]", text: "Event")
    expect(names).to eq(%w[War Today Feast])
  end

  it "creates an event, finding characters by search" do
    click_on "Add Event"
    within("dialog[open]") do
      fill_in "Name", with: " Duel "
      fill_in "Start Date", with: "2290-01-01"
      fill_in "End Date (optional)", with: "2290-01-02"
      fill_in "Search characters", with: "bra"
      expect(page).to have_no_field("Aria")
      check "Bran"
      fill_in "Search characters", with: "zzz"
      expect(page).to have_text("No characters match.")
      fill_in "Search characters", with: ""
      check "Aria"
      click_on "Add Event"
    end

    expect(page).to have_css(".bb-alert-success", text: "Event added successfully")
    expect(row("Duel")).to have_text("2290-01-02").and have_text("Aria").and have_text("Bran")
  end

  it "does not submit the form from the character search" do
    click_on "Add Event"
    within("dialog[open]") do
      fill_in "Name", with: "Duel"
      fill_in "Start Date", with: "2290-01-01"
      find_field("Search characters").send_keys("bra", :enter)
      expect(page).to have_button("Add Event")
      expect(page).to have_no_field("Aria")
    end
    expect(Event.count).to eq(4)
  end

  it "edits an event and keeps the filters" do
    fill_in "Search events", with: "war"
    expect(page).to have_no_css("tr", text: "Omen")
    click_on "Edit War"
    within("dialog[open]") do
      expect(page).to have_checked_field("Bran")
      uncheck "Bran"
      fill_in "End Date (optional)", with: ""
      click_on "Save Changes"
    end

    expect(page).to have_css(".bb-alert-success", text: "Event updated successfully")
    expect(names).to eq(["War"])
    expect(row("War").all("li").map { |item| item.text.squish }).to eq(["Aria age 20"])
  end

  it "shows a lifespan error and keeps the input" do
    click_on "Edit Feast"
    within("dialog[open]") do
      fill_in "Name", with: "Late Feast"
      check "Bran"
      click_on "Save Changes"

      expect(page).to have_text("Bran died 2292-02-03, and the event starts 2295-01-01")
      expect(page).to have_field("Name", with: "Late Feast")
      expect(page).to have_checked_field("Bran")
      uncheck "Bran"
      click_on "Save Changes"
    end

    expect(page).to have_css("tr", text: "Late Feast")
  end

  it "edits the Current Day without characters and cannot delete it" do
    expect(row("Today")).to have_no_button("Delete Today")
    expect(row("Today")).to have_link("View all ages")
    click_on "Edit Today"
    within("dialog[open]") do
      expect(page).to have_text("The Current Day event automatically includes all characters.")
      expect(page).to have_no_field("Aria")
      fill_in "Name", with: "Now"
      click_on "Save Changes"
    end
    expect(page).to have_css("tr", text: "Now")
    click_on "View all ages"

    expect(page).to have_css("h1", text: "Current Day")
  end

  it "deletes after confirmation only" do
    click_on "Delete Omen"
    within("dialog[open]") { click_on "Cancel" }
    expect(page).to have_no_css("dialog[open]")
    click_on "Delete Omen"
    within("dialog[open]") { click_on "Delete" }

    expect(page).to have_css(".bb-alert-success", text: "Event deleted")
    expect(page).to have_no_css("tr", text: "Omen")
  end
end
