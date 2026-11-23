require "rails_helper"

RSpec.describe "Summary" do
  let(:heroes) { create(:group, name: "Heroes") }
  let!(:aria) { create(:character, name: "Aria", birth_date: "2270-05-10", groups: [heroes]) }
  let!(:bran) { create(:character, name: "Bran", birth_date: "2250-01-01", groups: [heroes]) }
  let!(:cora) { create(:character, name: "Cora", birth_date: "2260-01-01") }

  before do
    create(:group, name: "Nobody")
    create(:event, name: "War", start_date: "2291-01-01", characters: [aria, bran, cora])
    sign_in
    click_on "Summary"
  end

  def expected(*characters)
    CharacterSummary.new(characters.map(&:id)).to_text
  end

  def output
    find_field("Summary text").value
  end

  it "generates for the selected characters" do
    expect(page).to have_button("Generate Summary", disabled: true)
    check "Aria"
    expect(page).to have_button("Clear (1)")
    click_on "Generate Summary"
    expect(page).to have_field("Summary text")
    expect(output).to eq(expected(aria))

    check "Cora"
    click_on "Generate Summary"
    expect(page).to have_field("Summary text", with: expected(aria, cora))
  end

  it "gives the same text as the API" do
    check "Bran"
    check "Cora"
    click_on "Generate Summary"
    expect(page).to have_field("Summary text")
    api = page.evaluate_async_script(<<~JS)
      fetch("/api/summary?characterIds=#{bran.id},#{cora.id}").then((r) => r.text()).then(arguments[0])
    JS

    expect(output).to eq(api)
  end

  it "selects, partly selects and clears a group" do
    chip = find_button("Heroes")
    expect(chip["aria-pressed"]).to eq("false")
    check "Aria"
    expect(chip["aria-pressed"]).to eq("mixed")
    click_on "Heroes"
    expect(chip["aria-pressed"]).to eq("true")
    expect(page).to have_checked_field("Bran")
    expect(page).to have_unchecked_field("Cora")
    click_on "Heroes"
    expect(chip["aria-pressed"]).to eq("false")
    expect(page).to have_unchecked_field("Aria")
    expect(find_button("Nobody")["aria-pressed"]).to eq("false")
  end

  it "searches, keeping the selection and hiding groups" do
    check "Aria"
    fill_in "Search characters", with: "CO"
    expect(page).to have_no_field("Aria")
    expect(page).to have_no_button("Heroes")
    check "Cora"
    expect(page).to have_button("Clear (2)")
    fill_in "Search characters", with: "zzz"
    expect(page).to have_text("No characters match.")
    fill_in "Search characters", with: ""

    expect(page).to have_checked_field("Aria")
    expect(page).to have_button("Heroes")
  end

  it "clears the selection and the text" do
    check "Aria"
    click_on "Generate Summary"
    expect(page).to have_field("Summary text")
    click_on "Clear (1)"

    expect(page).to have_unchecked_field("Aria")
    expect(page).to have_no_field("Summary text")
    expect(page).to have_text("Select characters on the left and click Generate Summary.")
    expect(page).to have_no_button("Clear")
    expect(page).to have_button("Generate Summary", disabled: true)
  end

  it "copies the text" do
    page.driver.browser.command("Browser.grantPermissions",
                                permissions: %w[clipboardReadWrite clipboardSanitizedWrite],
                                browserContextId: page.driver.browser.page.context_id)
    check "Aria"
    click_on "Generate Summary"
    click_on "Copy"

    expect(page).to have_button("Copied!")
    copied = page.evaluate_async_script("navigator.clipboard.readText().then(arguments[0])")
    expect(copied).to eq(expected(aria))
    expect(page).to have_button("Copy", exact: true, wait: 5)
  end

  it "says when the selected characters are gone" do
    check "Cora"
    cora.destroy!
    click_on "Generate Summary"

    expect(page).to have_text("No characters found for the given IDs")
  end
end
