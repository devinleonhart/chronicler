require "rails_helper"

RSpec.describe "Groups" do
  before do
    heroes = create(:group, name: "Heroes", description: "The good ones")
    create(:group, name: "Villains")
    create(:character, name: "Bran", groups: [heroes])
    create(:character, name: "Aria", groups: [heroes])
    sign_in
    click_on "Groups"
  end

  def row(name)
    find("tr", text: name)
  end

  it "lists groups with their members" do
    expect(page).to have_css(".bb-subtitle", exact_text: "2 groups")
    expect(row("Heroes")).to have_text("2").and have_text("Aria, Bran")
    expect(row("Villains")).to have_text("0")
  end

  it "creates a group" do
    click_on "Add Group"
    within("dialog[open]") do
      expect(page).to have_css("h2", text: "Add Group")
      fill_in "Name", with: "  Neutrals "
      fill_in "Description (optional)", with: "Neither"
      click_on "Add Group"
    end

    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_css(".bb-alert-success", text: "Group added successfully")
    expect(page).to have_css("tbody tr", count: 3)
    expect(Group.find_by!(name: "Neutrals").description).to eq("Neither")
  end

  it "shows an error in the dialog and keeps the input" do
    click_on "Add Group"
    within("dialog[open]") do
      fill_in "Name", with: " "
      fill_in "Description (optional)", with: "Kept"
      click_on "Add Group"

      expect(page).to have_text("Name can't be blank")
      expect(page).to have_field("Description (optional)", with: "Kept")
      fill_in "Name", with: "Fixed"
      click_on "Add Group"
    end

    expect(page).to have_css("tr", text: "Fixed")
  end

  it "edits a group" do
    click_on "Edit Heroes"
    within("dialog[open]") do
      expect(page).to have_field("Name", with: "Heroes")
      expect(page).to have_field("Description (optional)", with: "The good ones")
      fill_in "Name", with: "Champions"
      click_on "Save Changes"
    end

    expect(page).to have_css(".bb-alert-success", text: "Group updated successfully")
    expect(row("Champions")).to have_text("Aria, Bran")
    expect(page).to have_no_css("tr", text: "Heroes")
  end

  it "closes the dialog without saving" do
    click_on "Edit Heroes"
    within("dialog[open]") do
      fill_in "Name", with: "Lost"
      click_on "Cancel"
    end
    expect(page).to have_no_css("dialog[open]")

    click_on "Edit Heroes"
    within("dialog[open]") { expect(page).to have_field("Name", with: "Heroes") }
    find("dialog[open]").send_keys(:escape)
    expect(page).to have_no_css("dialog[open]")
  end

  it "searches by name and description" do
    fill_in "Search groups", with: "VILL"
    expect(page).to have_no_css("tr", text: "Heroes")
    expect(page).to have_css("tr", text: "Villains")
    expect(page).to have_current_path(/q=VILL/)

    fill_in "Search groups", with: "good ones"
    expect(page).to have_css("tr", text: "Heroes")
    expect(page).to have_no_css("tr", text: "Villains")

    fill_in "Search groups", with: "nothing"
    expect(page).to have_text('No groups match "nothing"')
  end

  it "keeps the search while editing" do
    fill_in "Search groups", with: "heroes"
    expect(page).to have_no_css("tr", text: "Villains")
    click_on "Edit Heroes"
    within("dialog[open]") do
      fill_in "Description (optional)", with: "Changed"
      click_on "Save Changes"
    end

    expect(page).to have_css(".bb-alert-success")
    expect(page).to have_field("Search groups", with: "heroes")
    expect(page).to have_no_css("tr", text: "Villains")
  end

  it "deletes a group after confirmation and keeps its characters" do
    click_on "Delete Heroes"
    within("dialog[open]") do
      expect(page).to have_text("Delete Group")
      expect(page).to have_text("Characters will remain but lose this group assignment.")
      click_on "Delete"
    end

    expect(page).to have_css(".bb-alert-success", text: "Group deleted")
    expect(page).to have_no_css("tr", text: "Heroes")
    expect(Character.count).to eq(2)
  end

  it "keeps a group when deletion is cancelled" do
    click_on "Delete Heroes"
    within("dialog[open]") { click_on "Cancel" }
    expect(page).to have_no_css("dialog[open]")
    click_on "Delete Heroes"
    find("dialog[open]").send_keys(:escape)
    expect(page).to have_no_css("dialog[open]")

    expect(page).to have_css("tr", text: "Heroes")
    expect(Group.count).to eq(2)
  end

  it "escapes names" do
    create(:group, name: "<b>Bold</b>")
    visit groups_path

    expect(page).to have_text("<b>Bold</b>")
  end

  it "asks to sign in again when the session has ended" do
    Session.destroy_all
    click_on "Add Group"

    expect(page).to have_css("h1", text: "Welcome Back")
  end

  it "invites a first group" do
    Group.destroy_all
    visit groups_path

    expect(page).to have_text("No groups yet. Add your first group!")
  end
end
