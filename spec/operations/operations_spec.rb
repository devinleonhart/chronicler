require "rails_helper"

# The operations, called without a request.
RSpec.describe "Operations" do
  def rejection
    yield
    nil
  rescue Rejection => error
    [error.message, error.status_code]
  end

  def id_of(record)
    record.fetch(:id)
  end

  it "reads and updates settings" do
    expect(SettingOperations.show).to include(name: "My Universe", currentDay: "0500-06-15")
    expect(SettingOperations.update("name" => " New ")).to include(name: "New")
    expect(rejection { SettingOperations.update("name" => nil) }).to eq(["Name must be a non-empty string", 400])
    expect(rejection { SettingOperations.update("endDate" => "x") })
      .to eq(["endDate must be a valid date string (YYYY-MM-DD)", 400])
    expect(rejection { SettingOperations.update("endDate" => "2300-02-31") })
      .to eq(["endDate must be a valid date string (YYYY-MM-DD)", 400])
    UniverseSetting.delete_all
    expect(rejection { SettingOperations.update({}) }).to eq(["Settings not found", 404])
  end

  it "manages groups" do
    group = GroupOperations.create("name" => " Heroes ", "description" => nil)
    expect(group).to include(name: "Heroes", description: nil, characterGroups: [])
    expect(GroupOperations.list).to eq([group])
    expect(GroupOperations.update(id_of(group), "description" => "Brave"))
      .to include(name: "Heroes", description: "Brave")
    expect(rejection { GroupOperations.create({}) }).to eq(["Group name is required", 400])
    expect(rejection { GroupOperations.update(id_of(group), "name" => "") }).to eq(["Group name is required", 400])
    expect(rejection { GroupOperations.create("name" => "x", "description" => 1) })
      .to eq(["Description must be a string or null", 400])
    GroupOperations.delete(id_of(group))
    %i[show delete].each do |name|
      expect(rejection { GroupOperations.public_send(name, id_of(group)) }).to eq(["Group not found", 404])
    end
    expect(rejection { GroupOperations.update(1, {}) }).to eq(["Group not found", 404])
  end

  describe "characters" do
    let(:group) { create(:group) }
    let(:aria) { CharacterOperations.create("name" => "Aria", "birthDate" => "2270-01-01", "groupIds" => [group.id]) }

    it "are read and changed" do
      expect(aria[:characterGroups].sole).to include(groupId: group.id)
      expect(CharacterOperations.list(name: "AR", birth_year: 2270, group_id: group.id)).to eq([aria])
      expect(CharacterOperations.placeholders("2270-01-01")).to eq([aria])
      expect(CharacterOperations.placeholders).to eq([])
      expect(CharacterOperations.update(id_of(aria), "deathDate" => "2290-01-01")[:deathDate]).to eq("2290-01-01")
      expect(CharacterOperations.update(id_of(aria), "deathDate" => nil)[:deathDate]).to be_nil
      expect(CharacterOperations.remove_group(id_of(aria), group.id)[:characterGroups]).to eq([])
      expect(CharacterOperations.add_group(id_of(aria), "groupId" => group.id)[:characterGroups].size).to eq(1)
      renamed = BulkCharacterOperation.update("updates" => [{ "id" => id_of(aria), "name" => "II" }])
      expect(renamed.sole[:name]).to eq("II")
      event = create(:event, characters: [Character.sole])
      expect(CharacterOperations.events(id_of(aria)).sole[:id]).to eq(event.id)
      CharacterOperations.delete(id_of(aria))
      expect(Character.count).to eq(0)
    end

    it "are rejected with the API's messages" do
      fields = { "name" => "A", "birthDate" => "2270-01-01" }
      {
        {} => "Character name is required",
        { "name" => "A" } => CharacterOperations::BIRTH_REQUIRED,
        fields.merge("deathDate" => "x") => CharacterOperations::DEATH,
        fields.merge("groupIds" => nil) => "groupIds must be an array",
        fields.merge("groupIds" => [999_999]) => "Groups not found: 999999",
        fields.merge("deathDate" => "2269-01-01") => "deathDate cannot be before birthDate"
      }.each { |sent, message| expect(rejection { CharacterOperations.create(sent) }).to eq([message, 400]) }

      %i[show events delete].each do |name|
        expect(rejection { CharacterOperations.public_send(name, 999_999) }).to eq(["Character not found", 404])
      end
      expect(rejection { CharacterOperations.update(999_999, {}) }).to eq(["Character not found", 404])
      expect(rejection { CharacterOperations.add_group(999_999, {}) })
        .to eq(["groupId must be a positive integer", 400])
      expect(rejection { CharacterOperations.add_group(999_999, "groupId" => 1) }).to eq(["Character not found", 404])
      expect(rejection { CharacterOperations.add_group(id_of(aria), "groupId" => 999_999) })
        .to eq(["Group not found", 404])
      expect(rejection { CharacterOperations.remove_group(999_999, 1) }).to eq(["Character not found", 404])
      expect { CharacterOperations.list(group_id: 99_999_999_999) }.to raise_error(RangeError)
    end

    it "are rejected in bulk, all or none" do
      id = id_of(aria)
      {
        {} => ["updates must be a non-empty array", 400],
        { "updates" => [{}] } => ["Each update must have a positive integer id (got: undefined)", 400],
        { "updates" => [{ "id" => id, "name" => "" }] } => ["Character #{id}: name must be a non-empty string", 400],
        { "updates" => [{ "id" => id, "name" => "X" }, { "id" => 999_999 }] } => ["Characters not found: 999999", 404],
        { "updates" => [{ "id" => id, "name" => "X" }, { "id" => id, "groupIds" => [999_999] }] } =>
          ["Character #{id}: Groups not found: 999999", 400]
      }.each { |fields, answer| expect(rejection { BulkCharacterOperation.update(fields) }).to eq(answer) }
      expect(Character.sole.name).to eq("Aria")
    end
  end

  describe "events" do
    let(:aria) { create(:character, name: "Aria", birth_date: "2270-01-01") }
    let(:war) { EventOperations.create("name" => "War", "startDate" => "2290-01-01", "characterIds" => [aria.id]) }

    it "are read and changed" do
      expect(war[:eventCharacters].sole).to include(characterId: aria.id)
      expect(EventOperations.list(name: "wa", start_after: "2290-01-01", start_before: "2290-01-01",
                                  character_id: aria.id)).to eq([war])
      expect(EventOperations.update(id_of(war), "endDate" => "2291-01-01")[:endDate]).to eq("2291-01-01")
      expect(EventOperations.remove_character(id_of(war), aria.id)[:eventCharacters]).to eq([])
      expect(EventOperations.add_character(id_of(war), "characterId" => aria.id)[:eventCharacters].size).to eq(1)
      expect(SummaryOperation.text([aria.id])).to include("1. War  [2290-01-01 – 2291-01-01]")
      EventOperations.delete(id_of(war))
      expect(Event.count).to eq(0)
    end

    it "are rejected with the API's messages" do
      fields = { "name" => "A", "startDate" => "2290-01-01" }
      {
        {} => "Event name is required",
        { "name" => "A" } => EventOperations::START_REQUIRED,
        fields.merge("endDate" => "x") => EventOperations::END_DATE,
        fields.merge("endDate" => "2289-01-01") => "endDate cannot be before startDate",
        fields.merge("characterIds" => "1") => "characterIds must be an array",
        fields.merge("characterIds" => [999_999]) => "Characters not found: 999999",
        fields.merge("startDate" => "2200-01-01", "characterIds" => [aria.id]) =>
          'Character "Aria" was not yet born when this event ended (born 2270-01-01, event ends 2200-01-01)'
      }.each { |sent, message| expect(rejection { EventOperations.create(sent) }).to eq([message, 400]) }

      current = create(:event, is_current_day: true)
      expect(rejection { EventOperations.delete(current.id) }).to eq(["Cannot delete the Current Day event", 400])
      %i[show delete].each do |name|
        expect(rejection { EventOperations.public_send(name, 999_999) }).to eq(["Event not found", 404])
      end
      expect(rejection { EventOperations.update(999_999, {}) }).to eq(["Event not found", 404])
      expect(rejection { EventOperations.add_character(1, {}) }).to eq(["characterId must be a positive integer", 400])
      expect(rejection { EventOperations.add_character(current.id, "characterId" => 999_999) })
        .to eq(["Characters not found: 999999", 400])
      expect(rejection { EventOperations.remove_character(999_999, 1) }).to eq(["Event not found", 404])
    end

    it "have no summary without characters" do
      expect(rejection { SummaryOperation.text([]) }).to eq(["At least one characterId is required", 400])
      expect(rejection { SummaryOperation.text([999_999]) }).to eq(["No characters found for the given IDs", 404])
      expect { SummaryOperation.text([99_999_999_999]) }.to raise_error(RangeError)
    end
  end

  it "parses ids" do
    expect(RecordId.parse("0007", "group")).to eq(7)
    expect(RecordId.parse(7, "group")).to eq(7)
    ["", "x", "0", "1.5", "-1", "2147483648", " 1", nil].each do |value|
      expect(rejection { RecordId.parse(value, "group") }).to eq(["Invalid group ID", 400])
    end
  end
end
