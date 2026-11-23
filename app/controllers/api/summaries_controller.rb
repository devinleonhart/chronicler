module Api
  class SummariesController < BaseController
    def show
      ids = query("characterIds").to_s.split(",").filter_map { |text| leading_integer(text) }.select(&:positive?)
      reject("At least one characterId is required") if ids.empty?

      summary = CharacterSummary.new(ids)
      reject("No characters found for the given IDs", :not_found) if summary.characters.empty?

      render plain: summary.to_text
    end
  end
end
