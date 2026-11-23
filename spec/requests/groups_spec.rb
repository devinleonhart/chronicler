require "rails_helper"

RSpec.describe "Groups pages" do
  let!(:group) { create(:group, name: "Heroes", description: "Brave") }

  context "when signed in" do
    before { sign_in }

    it "returns 422 for an invalid form" do
      post groups_path, params: { group: { name: " " } }
      expect(response).to have_http_status(:unprocessable_content)
      patch group_path(group), params: { group: { name: "x" * 256 } }
      expect(response).to have_http_status(:unprocessable_content)

      expect(Group.sole).to have_attributes(name: "Heroes")
    end

    it "trims a description and stores a blank one as none" do
      patch group_path(group), params: { group: { description: "  Bold " } }
      expect(group.reload.description).to eq("Bold")
      patch group_path(group), params: { group: { description: " " } }
      expect(group.reload.description).to be_nil
    end

    it "ignores fields outside the form" do
      patch group_path(group), params: { group: { id: 999, name: "Renamed", created_at: "2000-01-01" } }

      expect(group.reload).to have_attributes(name: "Renamed", id: group.id)
      expect(group.created_at.year).not_to eq(2000)
    end

    it "searches literally" do
      get groups_path(q: "%")

      expect(response.body).to include("No groups match")
      expect(response.body).not_to include("Heroes")
    end

    it "shows dialogs only in their frame" do
      [new_group_path, edit_group_path(group)].each do |path|
        get path
        expect(response).to redirect_to(groups_path)
        get path, headers: { "Turbo-Frame" => "dialog" }
        expect(response).to have_http_status(:ok)
      end
    end

    it "returns 404 for a missing group" do
      patch "/groups/999999", params: { group: { name: "x" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  it "refuses writes when signed out" do
    post groups_path, params: { group: { name: "New" } }
    expect(response).to redirect_to(new_session_path)
    delete group_path(group)
    expect(response).to redirect_to(new_session_path)

    expect(Group.sole).to eq(group)
  end

  it "refuses writes without a CSRF token" do
    sign_in
    with_forgery_protection do
      post groups_path, params: { group: { name: "New" } }
      expect(response).to have_http_status(:unprocessable_content)
      patch group_path(group), params: { group: { name: "Changed" } }
      expect(response).to have_http_status(:unprocessable_content)
      delete group_path(group)
      expect(response).to have_http_status(:unprocessable_content)
    end

    expect(Group.sole).to have_attributes(name: "Heroes")
  end
end
