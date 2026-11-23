module Api
  class CharactersController < BaseController
    DEFAULT_PLACEHOLDER = "2200-01-01".freeze
    BIRTH_REQUIRED = "birthDate is required and must be a valid date string (YYYY-MM-DD)".freeze
    BIRTH = "birthDate must be a valid date string (YYYY-MM-DD)".freeze
    DEATH = "deathDate must be a valid date string (YYYY-MM-DD) or null".freeze

    def index
      scope = characters
      scope = scope.name_contains(query("name")) if query("name").present?
      scope = scope.born_in(query_integer("birthYear")) if query_integer("birthYear")
      scope = scope.in_group(query_integer("groupId")) if query_integer("groupId")
      render_characters scope
    end

    def placeholders
      render_characters characters.where(birth_date: query("birthDate") || DEFAULT_PLACEHOLDER)
    end

    def events
      character = find(Character, path_id(:id, "character"))
      events = Event.with_character(character.id).includes(event_characters: :character).chronological
      render_json(events.map { |event| JsonRecord.event(event) })
    end

    def show
      render_character path_id(:id, "character")
    end

    def create
      check_name(body["name"], "Character name is required")
      check_fields(body, BIRTH_REQUIRED, birth_required: true)
      check_dates(Character, sent_dates(body, BIRTH_REQUIRED))
      character = Character.new(attributes(body))
      save(character)
      render_character character.id, :created
    end

    def update
      id = path_id(:id, "character")
      check_name(body["name"], "Character name is required") if body.key?("name")
      check_fields(body, BIRTH)
      check_dates(Character, sent_dates(body, BIRTH))
      character = find(Character, id)
      character.assign_attributes(attributes(body))
      save(character)
      render_character id
    end

    def destroy
      find(Character, path_id(:id, "character")).destroy!
      head :no_content
    end

    private

    def characters
      Character.includes(character_groups: :group).by_name
    end

    def render_characters(scope)
      render_json(scope.map { |character| JsonRecord.character(character) })
    end

    def render_character(id, status = :ok)
      render_json JsonRecord.character(find(characters, id)), status
    end

    def check_fields(fields, birth_message, birth_required: false)
      check_date(fields["birthDate"], birth_message) if birth_required || fields.key?("birthDate")
      check_date(fields["deathDate"], DEATH) unless fields["deathDate"].nil?
      check_list(fields["groupIds"], "groupIds must be an array") if fields.key?("groupIds")
    end

    def sent_dates(fields, birth_message)
      { birth_date: SentDate.new(fields["birthDate"], birth_message),
        death_date: SentDate.new(fields["deathDate"], DEATH) }.select { |_, date| date.value }
    end

    def attributes(fields)
      { "name" => :name, "birthDate" => :birth_date, "deathDate" => :death_date, "groupIds" => :group_ids }
        .filter_map { |field, attribute| [attribute, fields[field]] if fields.key?(field) }.to_h
    end
  end
end
