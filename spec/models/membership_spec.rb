require "rails_helper"

RSpec.describe "Memberships" do
  it "finds a group membership by both ids" do
    character = create(:character, groups: [create(:group)])
    group = character.groups.first

    membership = CharacterGroup.find([character.id, group.id])

    expect(membership).to have_attributes(character:, group:)
  end

  it "finds an event membership by both ids" do
    event = create(:event, characters: [create(:character)])
    character = event.characters.first

    membership = EventCharacter.find([event.id, character.id])

    expect(membership).to have_attributes(event:, character:)
  end

  it "removes a single membership" do
    group = create(:group)
    other = create(:group)
    character = create(:character, groups: [group, other])

    character.groups.delete(group)

    expect(character.reload.groups).to eq([other])
  end

  it "refuses a duplicate" do
    group = create(:group)
    character = create(:character, groups: [group])

    expect { CharacterGroup.create!(character:, group:) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
