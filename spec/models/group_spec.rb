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

  it "trims and requires a name" do
    expect(build(:group, name: "\u00a0 Name \u3000").name).to eq("Name")
    expect(build(:group, name: "\t ")).not_to be_valid
    expect(build(:group, name: nil)).not_to be_valid
  end

  it "limits its name to 255 characters" do
    expect(build(:group, name: "é" * 255)).to be_valid
    expect(build(:group, name: "é" * 256)).not_to be_valid
  end
end
