require "rails_helper"

RSpec.describe "Seeds" do
  def load_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "loads the sample universe in development, once" do
    allow(Rails.env).to receive(:development?).and_return(true)
    2.times { load_seeds }

    counts = [UniverseSetting, Group, Character, CharacterGroup, Event, EventCharacter].map(&:count)
    expect(counts).to eq([1, 11, 37, 37, 75, 81])
    expect(create(:character).id).to be > Character.where.not(id: Character.maximum(:id)).maximum(:id)
    expect(Event.find_by!(is_current_day: true).start_date).to eq(UniverseSetting.sole.current_day)
  end

  it "loads nothing elsewhere" do
    load_seeds

    expect(Character.count).to eq(0)
  end
end
