require "rails_helper"

RSpec.describe "LegacyConversion" do
  let(:version) { "20261123000000" }
  let(:legacy_schema) { Rails.root.join("db/legacy_schema.sql") }
  let(:seed) { Rails.root.join("contract/seed.sql") }
  let(:database) { SeparateDatabase.new("chronicler_conversion_test") }

  let(:tables) do
    {
      "UniverseSettings" => "universe_settings",
      "Group" => "groups",
      "Character" => "characters",
      "CharacterGroup" => "character_groups",
      "Event" => "events",
      "EventCharacter" => "event_characters"
    }
  end

  before { database.recreate }
  after { database.drop }

  def load_legacy
    database.load(legacy_schema)
    database.load(seed)
  end

  it "keeps every row, id and value" do
    load_legacy
    before = tables.keys.index_with { |table| [database.columns(table), database.rows(table)] }
    expect(before.transform_values { |_, rows| rows.size }).to eq(
      "UniverseSettings" => 1, "Group" => 11, "Character" => 37,
      "CharacterGroup" => 37, "Event" => 75, "EventCharacter" => 81
    )

    database.migrate_to(version)

    tables.each do |old, new|
      columns, rows = before.fetch(old)
      expect(database.columns(new)).to eq(columns.map(&:underscore))
      expect(database.rows(new)).to eq(rows)
    end
    remaining = database.query("SELECT tablename FROM pg_tables WHERE schemaname = 'public'").column_values(0)
    expect(remaining).to match_array(tables.values + SeparateDatabase::BOOKKEEPING)
  end

  it "leaves no legacy name behind" do
    load_legacy
    database.migrate_to(version)

    expect(database.dump("--schema-only")).not_to match(/"[^"]*[A-Z][^"]*"/)
  end

  it "reverses without loss" do
    load_legacy
    before = database.dump

    database.migrate_to(version)
    expect(database.dump).not_to eq(before)
    database.migrate_down(version)

    expect(database.dump).to eq(before)
  end

  it "reverses every migration without loss" do
    load_legacy
    before = database.dump
    database.prepare
    expect(database.dump).to include("CREATE TABLE public.mcp_tokens")
    database.migrate_to("0")

    expect(database.dump).to eq(before)
  end

  it "reaches the same schema from an empty database" do
    load_legacy
    database.migrate_to(version)
    converted = database.dump("--schema-only")

    database.recreate
    database.migrate_to(version, schema_file: false)

    expect(database.dump("--schema-only")).to eq(converted)
  end

  it "converts again after being reversed" do
    load_legacy
    database.migrate_to(version)
    converted = database.dump
    database.migrate_down(version)
    database.migrate_to(version)

    expect(database.dump).to eq(converted)
  end

  it "converts when preparing the database" do
    load_legacy
    database.prepare

    expect(database.rows("characters").size).to eq(37)
    expect(database.query("SELECT to_regclass('public.\"Character\"')").getvalue(0, 0)).to be_nil
  end

  it "takes the next id in each table" do
    load_legacy
    database.migrate_to(version)

    inserts = {
      "universe_settings" => "(name, start_date, end_date, current_day, updated_at) " \
                             "VALUES ('x', '1000-01-01', '2000-01-01', '1500-01-01', now())",
      "groups" => "(name, updated_at) VALUES ('x', now())",
      "characters" => "(name, birth_date, updated_at) VALUES ('x', '2200-01-01', now())",
      "events" => "(name, start_date, updated_at) VALUES ('x', '2200-01-01', now())"
    }
    ids = inserts.to_h do |table, rest|
      [table, database.query("INSERT INTO #{table} #{rest} RETURNING id").getvalue(0, 0).to_i]
    end
    expect(ids).to eq("universe_settings" => 2, "groups" => 12, "characters" => 38, "events" => 76)

    database.query("INSERT INTO character_groups VALUES (38, 12)")
    database.query("INSERT INTO event_characters VALUES (76, 38)")
  end

  it "rejects dates in another format" do
    load_legacy
    database.migrate_to(version)

    %w[universe_settings.start_date universe_settings.end_date universe_settings.current_day
       characters.birth_date characters.death_date events.start_date events.end_date].each do |name|
      table, column = name.split(".")
      ["2200-1-1", "x2200-01-0", "2200/01/01", "2200-01-1\n"].each do |value|
        expect { database.query("UPDATE #{table} SET #{column} = '#{value}'") }.to raise_error(PG::CheckViolation)
      end
    end
  end

  it "keeps cascading deletion" do
    load_legacy
    database.migrate_to(version)
    database.query("DELETE FROM characters")
    database.query("DELETE FROM events")

    expect(database.rows("character_groups")).to be_empty
    expect(database.rows("event_characters")).to be_empty
    expect(database.rows("groups").size).to eq(11)
  end

  it "refuses a database with only some legacy tables" do
    database.load(legacy_schema)
    database.query('DROP TABLE "EventCharacter"')

    expect { database.migrate_to(version) }.to raise_error(/Legacy tables are missing: EventCharacter/)
    expect(database.query("SELECT to_regclass('public.characters')").getvalue(0, 0)).to be_nil
  end
end
