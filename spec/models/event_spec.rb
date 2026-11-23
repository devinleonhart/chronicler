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

  def errors_of(attributes)
    build(:event, attributes).tap(&:validate).errors
  end

  describe "dates" do
    before { create(:universe_setting, start_date: "1000-01-01", end_date: "2320-12-31") }

    it "refuses dates outside the universe" do
      expect(errors_of(start_date: "0999-12-31")).to be_of_kind(:start_date, :before_universe)
      expect(errors_of(start_date: "2321-01-01")).to be_of_kind(:start_date, :after_universe)
      expect(errors_of(end_date: "2321-01-01")).to be_of_kind(:end_date, :after_universe)
      expect(build(:event, start_date: "1000-01-01", end_date: "2320-12-31")).to be_valid
    end

    it "refuses impossible dates" do
      expect(errors_of(start_date: "2300-02-31")).to be_of_kind(:start_date, :invalid_date)
      expect(errors_of(end_date: "2300-02-30")).to be_of_kind(:end_date, :invalid_date)
    end

    it "refuses an end before its start" do
      expect(errors_of(start_date: "2290-01-02", end_date: "2290-01-01")).to be_of_kind(:end_date, :before_start)
      expect(build(:event, start_date: "2290-01-01", end_date: "2290-01-01")).to be_valid
    end

    it "refuses an end before its start when only one changes" do
      event = create(:event, start_date: "2290-01-01", end_date: "2291-01-01")

      expect(event.update(start_date: "2291-01-02")).to be(false)
      expect(event.reload.update(end_date: "2289-12-31")).to be(false)
    end
  end

  describe "lifespans" do
    let(:character) { create(:character, birth_date: "2270-01-01", death_date: "2280-01-01") }

    def event_between(start_date, end_date)
      build(:event, start_date:, end_date:, character_ids: [character.id]).tap(&:validate).errors
    end

    it "accepts an overlap of one day" do
      expect(event_between("2260-01-01", "2270-01-01")).to be_empty
      expect(event_between("2270-01-01", nil)).to be_empty
      expect(event_between("2280-01-01", "2290-01-01")).to be_empty
      expect(event_between("2280-01-01", nil)).to be_empty
    end

    it "refuses a character not yet born" do
      expect(event_between("2260-01-01", "2269-12-31")).to be_of_kind(:characters, :unborn)
      expect(event_between("2269-12-31", nil)).to be_of_kind(:characters, :unborn)
    end

    it "refuses a character already dead" do
      expect(event_between("2280-01-02", nil)).to be_of_kind(:characters, :dead)
    end

    it "rechecks members when a date changes" do
      event = create(:event, start_date: "2275-01-01", characters: [character])

      expect(event.update(start_date: "2281-01-01")).to be(false)
      expect(event.reload.update(start_date: "2260-01-01", end_date: "2265-01-01")).to be(false)
      expect(event.reload.update(start_date: "2260-01-01", end_date: "2271-01-01")).to be(true)
    end

    context "with a violation already stored" do
      let(:event) { create(:event, start_date: "2290-01-01") }
      let(:other) { create(:character, birth_date: "2260-01-01") }

      before { EventCharacter.create!(event:, character:) }

      it "skips the check unless dates or members change" do
        resent = { name: "Again", start_date: "2290-01-01", end_date: nil, character_ids: [character.id] }

        expect(event.update(name: "Renamed")).to be(true)
        expect(event.update(resent)).to be(true)
        expect(event.update(end_date: "2291-01-01")).to be(false)
        expect(event.reload.update(character_ids: [character.id, other.id])).to be(false)
        expect(event.reload.update(character_ids: [other.id])).to be(true)
      end

      it "checks only the character being added" do
        expect(event.add_character(other.id)).to be(true)
        expect(event.reload.characters).to contain_exactly(character, other)
      end
    end
  end

  describe "#add_character" do
    let(:event) { create(:event, start_date: "2275-01-01") }

    it "adds once" do
      character = create(:character)
      2.times { expect(event.add_character(character.id)).to be(true) }

      expect(event.reload.characters).to eq([character])
    end

    it "refuses unknown, unborn and dead characters" do
      unborn = create(:character, birth_date: "2276-01-01")
      dead = create(:character, birth_date: "2250-01-01", death_date: "2274-12-31")

      { 999_999 => :unknown, unborn.id => :unborn, dead.id => :dead }.each do |id, type|
        expect(event.add_character(id)).to be(false)
        expect(event.errors).to be_of_kind(:characters, type)
      end
      expect(EventCharacter.count).to eq(0)
    end
  end

  it "refuses unknown character ids and writes nothing" do
    event = create(:event, name: "Kept")

    expect(event.update(name: "Lost", character_ids: [create(:character).id, 999_999])).to be(false)
    expect(event.errors).to be_of_kind(:characters, :unknown)
    expect(event.reload).to have_attributes(name: "Kept", characters: [])
  end

  it "cannot be deleted while it is the Current Day" do
    event = create(:event, is_current_day: true)

    expect(event.destroy).to be(false)
    expect(event.errors).to be_of_kind(:base, :current_day)
    expect(described_class).to exist(event.id)
  end
end
