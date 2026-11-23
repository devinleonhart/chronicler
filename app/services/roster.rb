# The characters as they are on a day, the living first.
class Roster
  Entry = Data.define(:character, :years, :deceased) do
    def age_text
      deceased ? "#{years} at death" : years.to_s
    end
  end

  def initialize(day)
    @day = day
  end

  def living
    entries.reject(&:deceased)
  end

  def deceased
    entries.select(&:deceased)
  end

  # Each group that has members, with their entries.
  def by_group
    Group.by_name.filter_map do |group|
      members = entries.select { |entry| entry.character.group_ids.include?(group.id) }
      [group, members] if members.any?
    end
  end

  def ungrouped
    entries.select { |entry| entry.character.group_ids.empty? }
  end

  private

  def entries
    @entries ||= begin
      all = Character.includes(:groups).by_name.map { |character| entry(character) }
      all.partition { |entry| !entry.deceased }.flatten
    end
  end

  def entry(character)
    age = AgeCalculator.on(character.birth_date, @day, character.death_date)
    Entry.new(character:, years: age.years, deceased: age.deceased)
  end
end
