require "rails_helper"

RSpec.describe Character do
  it { is_expected.to have_many(:character_groups).dependent(:delete_all) }
  it { is_expected.to have_many(:groups).through(:character_groups) }
  it { is_expected.to have_many(:event_characters).dependent(:delete_all) }
  it { is_expected.to have_many(:events).through(:event_characters) }

  it "loses only its own memberships when deleted" do
    group = create(:group)
    event = create(:event)
    other = create(:character, groups: [group], events: [event])
    character = create(:character, groups: [group], events: [event])

    character.destroy!

    expect(group.reload.characters).to eq([other])
    expect(event.reload.characters).to eq([other])
  end
end
