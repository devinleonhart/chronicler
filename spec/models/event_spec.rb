require "rails_helper"

RSpec.describe Event do
  it { is_expected.to have_many(:event_characters).dependent(:delete_all) }
  it { is_expected.to have_many(:characters).through(:event_characters) }

  it "keeps its characters when deleted" do
    character = create(:character)
    event = create(:event, characters: [character])

    expect { event.destroy! }.to change(EventCharacter, :count).by(-1)
    expect(character.reload.events).to be_empty
  end

  it "is not the Current Day unless marked" do
    expect(create(:event).reload.is_current_day).to be(false)
  end
end
