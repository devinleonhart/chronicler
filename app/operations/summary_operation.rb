module SummaryOperation
  extend OperationChecks

  def self.text(ids)
    reject("At least one characterId is required") if ids.empty?

    ids.each { |id| in_range(id) }
    summary = CharacterSummary.new(ids)
    reject("No characters found for the given IDs", :not_found) if summary.characters.empty?

    summary.to_text
  end
end
