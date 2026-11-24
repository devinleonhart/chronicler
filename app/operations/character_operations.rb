module CharacterOperations
  extend OperationChecks

  DEFAULT_PLACEHOLDER = "2200-01-01".freeze
  BIRTH_REQUIRED = "birthDate is required and must be a valid date string (YYYY-MM-DD)".freeze
  BIRTH = "birthDate must be a valid date string (YYYY-MM-DD)".freeze
  DEATH = "deathDate must be a valid date string (YYYY-MM-DD) or null".freeze
  FIELDS = { "name" => :name, "birthDate" => :birth_date, "deathDate" => :death_date, "groupIds" => :group_ids }.freeze

  class << self
    def list(name: nil, birth_year: nil, group_id: nil)
      scope = characters
      scope = scope.name_contains(name) if name.present?
      scope = scope.born_in(in_range(birth_year)) if birth_year
      scope = scope.in_group(in_range(group_id)) if group_id
      present(scope)
    end

    def list_of(ids)
      present(characters.where(id: ids))
    end

    def placeholders(birth_date = nil)
      present(characters.where(birth_date: birth_date || DEFAULT_PLACEHOLDER))
    end

    def show(id)
      Api::JsonRecord.character(find(characters, id))
    end

    def events(id)
      events = Event.with_character(find(Character, id).id)
      events.includes(event_characters: :character).chronological.map { |event| Api::JsonRecord.event(event) }
    end

    def create(fields)
      check_name(fields["name"], "Character name is required")
      check_fields(fields, BIRTH_REQUIRED, birth_required: true)
      check_dates(Character, sent_dates(fields, BIRTH_REQUIRED))
      character = Character.new(attributes(fields, FIELDS))
      save(character)
      show(character.id)
    end

    def update(id, fields)
      check_name(fields["name"], "Character name is required") if fields.key?("name")
      check_fields(fields, BIRTH)
      check_dates(Character, sent_dates(fields, BIRTH))
      character = find(Character, id)
      character.assign_attributes(attributes(fields, FIELDS))
      save(character)
      show(id)
    end

    def delete(id)
      find(Character, id).destroy!
    end

    def add_group(id, fields)
      group_id = fields["groupId"]
      reject("groupId must be a positive integer") unless positive_integer?(group_id)

      character = find(Character, id)
      character.add_group(find(Group, in_range(group_id.to_i)))
      show(id)
    end

    def remove_group(id, group_id)
      find(Character, id).character_groups.where(group_id:).delete_all
      show(id)
    end

    private

    def characters
      Character.includes(character_groups: :group).by_name
    end

    def present(scope)
      scope.map { |character| Api::JsonRecord.character(character) }
    end

    def check_fields(fields, birth_message, birth_required: false)
      check_date(fields["birthDate"], birth_message) if birth_required || fields.key?("birthDate")
      check_date(fields["deathDate"], DEATH) unless fields["deathDate"].nil?
      check_list(fields["groupIds"], "groupIds must be an array") if fields.key?("groupIds")
    end

    def sent_dates(fields, birth_message)
      { birth_date: OperationChecks::SentDate.new(fields["birthDate"], birth_message),
        death_date: OperationChecks::SentDate.new(fields["deathDate"], DEATH) }.select { |_, date| date.value }
    end
  end
end
