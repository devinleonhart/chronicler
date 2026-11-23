require "rails_helper"

RSpec.describe "Summary API" do
  let!(:aria) { create(:character, name: "Aria", birth_date: "0400-03-15") }
  let!(:bran) { create(:character, name: "Bran", birth_date: "0410-05-01", death_date: "0470-01-01") }
  let!(:cora) { create(:character, name: "Cora", birth_date: "0420-01-01") }

  def summary(*ids)
    get "/api/summary?characterIds=#{ids.join(',')}"
    response.body
  end

  it "summarizes one character" do
    create(:event, name: "War", start_date: "0450-01-01", end_date: "0452-12-31", characters: [cora, aria, bran])
    create(:event, name: "Alone", start_date: "0440-03-15", characters: [aria])
    create(:event, name: "Now", start_date: "0445-01-01", is_current_day: true, characters: [aria])

    expect(summary(aria.id)).to eq(<<~TEXT)
      CHARACTER SUMMARY: Aria
      Born: 0400-03-15  |  Living

      Events:

      1. Alone  [0440-03-15]
         Age: 40  |  Also present: none

      2. War  [0450-01-01 – 0452-12-31]
         Age: 49–52  |  Also present: Bran (age 39–42), Cora (age 30–32)
    TEXT
    expect(response.media_type).to eq("text/plain")
    expect(response.headers["Content-Type"]).to eq("text/plain; charset=utf-8")
  end

  it "summarizes several characters" do
    create(:event, name: "War", start_date: "0450-01-01", characters: [aria, bran, cora])

    expect(summary(bran.id, aria.id)).to eq(<<~TEXT)
      SUMMARY: Aria, Bran
      Generated: #{Time.now.utc.to_date.iso8601}

      Characters:
        Aria                    Born: 0400-03-15  |  Living
        Bran                    Born: 0410-05-01  |  Died: 0470-01-01

      Events involving any selected character (chronological):

      1. War  [0450-01-01]
         Selected present:  Aria (age 49), Bran (age 39)
         Others present:    Cora (age 30)
    TEXT
  end

  it "says when there are no events" do
    expect(summary(bran.id)).to eq(<<~TEXT)
      CHARACTER SUMMARY: Bran
      Born: 0410-05-01  |  Died: 0470-01-01

      Events:

        (no events found)
    TEXT
  end

  it "orders tied events by id" do
    first = create(:event, name: "First", start_date: "0450-01-01", characters: [aria])
    create(:event, name: "Second", start_date: "0450-01-01", characters: [aria])
    first.update!(end_date: "0450-01-01")

    expect(summary(aria.id)).to match(/1\. First.*2\. Second/m)
  end

  it "requires an id" do
    ["", "abc", "0,-1"].each do |ids|
      summary(ids)

      expect(response).to have_error("At least one characterId is required")
    end
  end

  it "returns 404 when nobody is found" do
    summary(9999)

    expect(response).to have_http_status(:not_found)
    expect(json).to eq("error" => "No characters found for the given IDs")
  end
end
