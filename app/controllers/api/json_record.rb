module Api
  # The API's JSON. Timestamps separate date and time with a space, or with T in nested records.
  module JsonRecord
    module_function

    def setting(record)
      base(record).merge(name: record.name, startDate: record.start_date, endDate: record.end_date,
                         currentDay: record.current_day)
    end

    def group(record)
      memberships = record.character_groups.sort_by(&:character_id).map do |membership|
        { characterId: membership.character_id, groupId: membership.group_id,
          character: character_fields(membership.character, "T") }
      end
      group_fields(record).merge(characterGroups: memberships)
    end

    def character(record)
      memberships = record.character_groups.sort_by(&:group_id).map do |membership|
        { characterId: membership.character_id, groupId: membership.group_id,
          group: group_fields(membership.group, "T") }
      end
      character_fields(record).merge(characterGroups: memberships)
    end

    def event(record)
      memberships = record.event_characters.sort_by(&:character_id).map do |membership|
        { eventId: membership.event_id, characterId: membership.character_id,
          character: character_fields(membership.character, "T") }
      end
      base(record).merge(name: record.name, startDate: record.start_date, endDate: record.end_date,
                         isCurrentDay: record.is_current_day, eventCharacters: memberships)
    end

    def group_fields(record, separator = " ")
      base(record, separator).merge(name: record.name, description: record.description)
    end

    def character_fields(record, separator = " ")
      base(record, separator).merge(name: record.name, birthDate: record.birth_date, deathDate: record.death_date)
    end

    def base(record, separator = " ")
      { id: record.id, createdAt: timestamp(record.created_at, separator),
        updatedAt: timestamp(record.updated_at, separator) }
    end

    def timestamp(time, separator)
      time.utc.strftime("%Y-%m-%d#{separator}%H:%M:%S.%L")
    end
  end
end
