require "rails_helper"

RSpec.describe Group do
  it { is_expected.to have_many(:character_groups).dependent(:delete_all) }
  it { is_expected.to have_many(:characters).through(:character_groups) }

  it "keeps its characters when deleted" do
    character = create(:character)
    group = create(:group, characters: [character])

    expect { group.destroy! }.to change(CharacterGroup, :count).by(-1)
    expect(character.reload.groups).to be_empty
  end
end
