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

  describe "dates" do
    before { create(:universe_setting, start_date: "1000-01-01", end_date: "2320-12-31") }

    def errors_of(attributes)
      build(:character, attributes).tap(&:validate).errors
    end

    it "accepts the bounds themselves" do
      expect(build(:character, birth_date: "1000-01-01", death_date: "2320-12-31")).to be_valid
    end

    it "refuses dates outside the universe" do
      expect(errors_of(birth_date: "0999-12-31")).to be_of_kind(:birth_date, :before_universe)
      expect(errors_of(birth_date: "2321-01-01")).to be_of_kind(:birth_date, :after_universe)
      expect(errors_of(death_date: "2321-01-01")).to be_of_kind(:death_date, :after_universe)
    end

    it "does not recheck unchanged dates against the universe" do
      character = create(:character, birth_date: "2270-01-01")
      UniverseSetting.sole.update!(start_date: "2280-01-01")

      expect(character.update(name: "Renamed")).to be(true)
      expect(character.update(birth_date: "2270-01-02")).to be(false)
    end

    it "refuses impossible dates" do
      %w[2300-02-31 1500-02-29 2100-02-29 2300-00-10 2300-13-01 2300-01-00 x 2300-1-1].each do |date|
        expect(errors_of(birth_date: date)).to be_of_kind(:birth_date, :invalid_date)
      end
    end

    it "accepts leap days of the Gregorian calendar" do
      %w[1600-02-29 2000-02-29 2296-02-29].each { |date| expect(build(:character, birth_date: date)).to be_valid }
    end

    it "refuses a death before birth" do
      expect(errors_of(birth_date: "2270-01-02", death_date: "2270-01-01")).to be_of_kind(:death_date, :before_birth)
      expect(build(:character, birth_date: "2270-01-01", death_date: "2270-01-01")).to be_valid
    end

    it "refuses a death before birth when only one changes" do
      character = create(:character, birth_date: "2270-01-01", death_date: "2280-01-01")

      expect(character.update(birth_date: "2280-01-02")).to be(false)
      expect(character.reload.update(death_date: "2269-12-31")).to be(false)
    end

    it "requires a birth date and treats a blank death date as none" do
      expect(build(:character, birth_date: nil)).not_to be_valid
      expect(build(:character, death_date: "").death_date).to be_nil
    end
  end

  describe "group_ids" do
    let(:groups) { create_list(:group, 2) }
    let(:character) { create(:character, groups: [groups.first]) }

    it "replaces groups on save" do
      character.group_ids = [groups.second.id]
      expect(character.group_ids).to eq([groups.second.id])
      expect(described_class.find(character.id).groups).to eq([groups.first])

      character.save!

      expect(character.reload.groups).to eq([groups.second])
    end

    it "accepts ids of the kinds that JSON and forms send, once each" do
      first, second = groups.map(&:id)
      character.update!(group_ids: [first.to_s, second.to_f, second])

      expect(character.reload.group_ids).to contain_exactly(first, second)
    end

    it "refuses unknown ids and writes nothing" do
      [999_999, 99_999_999_999, -1, 0, 1.5, nil, "x", true, {}].each do |id|
        expect(character.update(name: "Lost", group_ids: [groups.second.id, id])).to be(false)
        expect(character.errors).to be_of_kind(:groups, :unknown)
        expect(described_class.find(character.id)).to have_attributes(groups: [groups.first])
        expect(described_class.find(character.id).name).not_to eq("Lost")
        character.reload
      end
    end

    it "creates nothing with unknown ids" do
      expect(described_class.create(attributes_for(:character, group_ids: [999_999]))).not_to be_persisted
      expect(described_class.count).to eq(0)
    end

    it "rolls back when the memberships cannot be written" do
      character
      allow(CharacterGroup).to receive(:new).and_raise(ActiveRecord::StatementInvalid)

      expect { character.update(name: "Lost", group_ids: groups.map(&:id)) }
        .to raise_error(ActiveRecord::StatementInvalid)
      expect(described_class.find(character.id)).to have_attributes(groups: [groups.first])
      expect(described_class.find(character.id).name).not_to eq("Lost")
    end
  end
end
