require "rails_helper"

RSpec.describe "Characters pages" do
  let!(:character) { create(:character, name: "Aria", groups: [group]) }
  let(:group) { create(:group) }

  context "when signed in" do
    before { sign_in }

    it "returns 422 for an invalid form" do
      post characters_path, params: { character: { name: "", birth_date: "2270-01-01" } }
      expect(response).to have_http_status(:unprocessable_content)
      [{ birth_date: "2300-02-31" }, { birth_date: "" }, { death_date: "2269-01-01" }, { group_ids: ["", "9999"] }]
        .each do |fields|
          patch character_path(character), params: { character: fields }
          expect(response).to have_http_status(:unprocessable_content)
        end

      expect(Character.sole).to have_attributes(birth_date: "2270-01-01", groups: [group])
    end

    it "clears groups with the form's blank value and keeps them without it" do
      patch character_path(character), params: { character: { name: "Renamed" } }
      expect(character.reload.groups).to eq([group])
      patch character_path(character), params: { character: { group_ids: [""] } }
      expect(character.reload.groups).to be_empty
    end

    it "searches names and groups literally" do
      get characters_path(q: "_")

      expect(response.body).to include("No characters match")
    end
  end

  it "refuses a write without a CSRF token" do
    sign_in
    with_forgery_protection { delete character_path(character) }

    expect(response).to have_http_status(:unprocessable_content)
    expect(Character).to exist(character.id)
  end

  it "refuses writes when signed out" do
    delete character_path(character)

    expect(response).to redirect_to(new_session_path)
    expect(Character).to exist(character.id)
  end
end
