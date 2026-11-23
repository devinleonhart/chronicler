require "rails_helper"

RSpec.describe "Timeline" do
  let(:heroes) { create(:group, name: "Heroes") }

  before do
    create(:universe_setting, start_date: "2250-01-01", end_date: "2310-12-31")
    aria = create(:character, name: "Aria", birth_date: "2270-05-10", groups: [heroes])
    create(:event, name: "War", start_date: "2291-01-01", end_date: "2293-06-01", characters: [aria])
    create(:event, name: "<b>x</b>", start_date: "2280-01-01")
    create(:event, name: "Today", start_date: "2300-09-25", is_current_day: true)
    sign_in
    # Records policy violations and errors that would otherwise only reach the console.
    page.driver.browser.evaluate_on_new_document(<<~JS)
      window.problems = []
      addEventListener("securitypolicyviolation", (e) => problems.push([e.violatedDirective, e.blockedURI, e.sourceFile, e.lineNumber, e.columnNumber, e.sample].join(" ")))
      addEventListener("error", (e) => problems.push(e.message))
      addEventListener("unhandledrejection", (e) => problems.push(String(e.reason)))
      const error = console.error
      console.error = (...args) => { problems.push(args.join(" ")); error(...args) }
    JS
    visit events_path
  end

  def open_timeline
    click_on "Timeline"
    expect(page).to have_css(".vis-item-content", count: 3)
  end

  def items
    all(".vis-item .vis-item-content").map(&:text)
  end

  it "shows one item per filtered event" do
    open_timeline
    expect(items).to contain_exactly("War", "<b>x</b>", "Today")
    check "Heroes", allow_label_click: true

    expect(page).to have_css(".vis-item-content", count: 2)
    expect(items).to contain_exactly("War", "Today")
    expect(page).to have_current_path(/view=timeline/)
  end

  it "marks the Current Day" do
    open_timeline

    expect(page).to have_css(".vis-custom-time.currentDay", visible: :all)
    expect(page).to have_css(".vis-item.item-current-day", text: "Today")
  end

  it "opens an item's dialog, again after closing it" do
    open_timeline
    2.times do
      find(".vis-item-content", text: "War").click
      within("dialog[open]") do
        expect(page).to have_field("Name", with: "War")
        click_on "Cancel"
      end
      expect(page).to have_no_css("dialog[open]")
    end
  end

  it "returns to the timeline after saving" do
    open_timeline
    find(".vis-item-content", text: "War").click
    within("dialog[open]") do
      fill_in "Name", with: "Peace"
      click_on "Save Changes"
    end

    expect(page).to have_css(".vis-item-content", text: "Peace")
  end

  it "shows names as text, also in tooltips" do
    open_timeline
    find(".vis-item-content", text: "<b>x</b>").hover

    expect(page).to have_css(".vis-tooltip", text: "<b>x</b>")
    expect(page).to have_no_css(".vis-item b, .vis-tooltip b")
  end

  it "causes no errors or policy violations" do
    open_timeline
    click_on "List"
    expect(page).to have_css("tbody tr", count: 3)
    open_timeline

    expect(page.evaluate_script("window.problems")).to eq([])
  end

  it "says when nothing matches" do
    open_timeline
    fill_in "Search events", with: "nothing"

    expect(page).to have_text("No events match the current filters.")
  end
end
