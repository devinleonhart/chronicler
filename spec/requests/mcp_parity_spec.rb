require "rails_helper"

# Compares /mcp with the stdio server it replaced. The fixture holds tool calls, what that
# server answered to them in order, from the sample universe, and the rows it left.
RSpec.describe "MCP parity" do
  include_context "with MCP"

  let(:fixture) { JSON.parse(Rails.root.join("spec/fixtures/files/mcp_parity.json").read) }

  before do
    travel_to(Time.utc(2026, 1, 1))
    token
    allow(Rails.env).to receive(:development?).and_return(true)
  end

  # The database's clock, which fills created_at, does not stop.
  def load_sample
    load Rails.root.join("db/seeds.rb")
    [UniverseSetting, Group, Character, Event].each { |model| model.update_all(created_at: Time.current) } # rubocop:disable Rails/SkipsModelValidations
  end

  def start_ids_from_rows
    %w[universe_settings groups characters events].each do |table|
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end
  end

  # An error is now marked as one, so that mark is left out.
  def content(answer)
    answer["error"] ? [answer["error"]["code"], answer["error"]["message"]] : answer.dig("result", "content")
  end

  def rows
    JSON.parse(all_rows.transform_keys(&:name).to_json)
  end

  ["settings", "groups", "characters", "events", "summary", "an empty universe", "other arguments"].each do |section|
    it "holds for #{section}" do
      recorded = fixture.fetch(section)
      load_sample unless section == "an empty universe"
      start_ids_from_rows

      recorded["calls"].zip(recorded["contents"]).each do |(name, arguments), expected|
        ChroniclerMcp::Limits.reset
        actual = content(call_tool(name, arguments, token:))
        expect(actual).to eq(expected), "#{name} #{arguments}\nwas:  #{expected}\n/mcp: #{actual}"
      end
      expect(rows).to eq(recorded["rows"])
    end
  end

  it "covers every tool" do
    names = fixture.values.flat_map { |recorded| recorded["calls"].map(&:first) }

    expect(fixture.size).to eq(7)
    expect(names.uniq - ["drop_everything"]).to match_array(ChroniclerMcp.tools.map(&:name))
    expect(names.size).to eq(361)
  end
end
