# A plain-text account of the events of one or more characters.
class CharacterSummary
  NAME_WIDTH = 24

  attr_reader :characters

  def initialize(character_ids)
    @selected = character_ids.to_set
    @characters = Character.where(id: character_ids).by_name.to_a
  end

  def to_text
    [*(single? ? single_heading : shared_heading), *event_lines, ""].join("\n")
  end

  private

  def single?
    characters.one?
  end

  def single_heading
    character = characters.first
    ["CHARACTER SUMMARY: #{character.name}", life(character), "", "Events:"]
  end

  def shared_heading
    [
      "SUMMARY: #{characters.map(&:name).join(', ')}",
      "Generated: #{Time.now.utc.strftime('%Y-%m-%d')}",
      "",
      "Characters:",
      *characters.map { |character| "  #{pad(character.name)}#{life(character)}" },
      "",
      "Events involving any selected character (chronological):"
    ]
  end

  def life(character)
    status = character.death_date ? "Died: #{character.death_date}" : "Living"
    "Born: #{character.birth_date}  |  #{status}"
  end

  # Counts UTF-16 units, as JavaScript's padEnd does.
  def pad(name)
    name + (" " * [NAME_WIDTH - (name.encode("UTF-16LE").bytesize / 2), 0].max)
  end

  def event_lines
    return ["", "  (no events found)"] if events.empty?

    events.each.with_index(1).flat_map do |event, number|
      dates = [event.start_date, event.end_date].compact.join(" – ")
      ["", "#{number}. #{event.name}  [#{dates}]", *presence_lines(event)]
    end
  end

  def presence_lines(event)
    selected, others = event.characters.sort_by(&:id).partition { |character| @selected.include?(character.id) }
    if single?
      age = age_during(event, characters.first)
      return ["   Age: #{age}  |  Also present: #{people(event, others)}"]
    end

    lines = ["   Selected present:  #{people(event, selected)}"]
    lines << "   Others present:    #{people(event, others)}" if others.any?
    lines
  end

  def people(event, list)
    return "none" if list.empty?

    list.map { |character| "#{character.name} (age #{age_during(event, character)})" }.join(", ")
  end

  def age_during(event, character)
    AgeCalculator.range(character.birth_date, event.start_date, event.end_date)
  end

  def events
    @events ||= Event.with_character(characters.map(&:id)).where(is_current_day: false)
                     .includes(:characters).chronological.to_a
  end
end
