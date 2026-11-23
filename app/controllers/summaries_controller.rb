class SummariesController < ApplicationController
  def show
    @characters = Character.includes(:character_groups).by_name
    @groups = Group.by_name
    @text, @error = generate if params.key?(:ids)
  end

  private

  def generate
    ids = text_param(:ids).split(",").filter_map { |id| StagedMembers.parse_id(id) }
    return [nil, "At least one characterId is required"] if ids.empty?

    summary = CharacterSummary.new(ids)
    return [nil, "No characters found for the given IDs"] if summary.characters.empty?

    [summary.to_text, nil]
  end
end
