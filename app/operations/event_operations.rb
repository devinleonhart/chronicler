module EventOperations
  extend OperationChecks

  START_REQUIRED = "startDate is required and must be a valid date string (YYYY-MM-DD)".freeze
  START = "startDate must be a valid date string (YYYY-MM-DD)".freeze
  END_DATE = "endDate must be a valid date string (YYYY-MM-DD) or null".freeze
  FIELDS = { "name" => :name, "startDate" => :start_date, "endDate" => :end_date,
             "characterIds" => :character_ids }.freeze

  class << self
    def list(name: nil, start_after: nil, start_before: nil, character_id: nil)
      scope = events.chronological
      scope = scope.name_contains(name) if name.present?
      scope = scope.starting_from(start_after) if start_after.present?
      scope = scope.starting_until(start_before) if start_before.present?
      scope = scope.with_character(in_range(character_id)) if character_id
      scope.map { |event| Api::JsonRecord.event(event) }
    end

    def show(id)
      Api::JsonRecord.event(find(events, id))
    end

    def create(fields)
      check_name(fields["name"], "Event name is required")
      check_fields(fields, START_REQUIRED, start_required: true)
      event = Event.new(attributes(fields, FIELDS))
      save(event)
      show(event.id)
    end

    def update(id, fields)
      check_name(fields["name"], "Event name is required") if fields.key?("name")
      check_fields(fields, START)
      event = find(Event, id)
      event.assign_attributes(attributes(fields, FIELDS))
      save(event)
      show(id)
    end

    def delete(id)
      event = find(Event, id)
      reject(Api::ErrorMessage.for(event.errors.first)) unless event.destroy
    end

    def add_character(id, fields)
      character_id = fields["characterId"]
      reject("characterId must be a positive integer") unless positive_integer?(character_id)

      event = find(Event, id)
      reject(Api::ErrorMessage.for(event.errors.first)) unless event.add_character(character_id.to_i)
      show(id)
    end

    def remove_character(id, character_id)
      find(Event, id).event_characters.where(character_id:).delete_all
      show(id)
    end

    private

    def events
      Event.includes(event_characters: :character)
    end

    def check_fields(fields, start_message, start_required: false)
      check_date(fields["startDate"], start_message) if start_required || fields.key?("startDate")
      check_date(fields["endDate"], END_DATE) unless fields["endDate"].nil?
      check_list(fields["characterIds"], "characterIds must be an array") if fields.key?("characterIds")
      dates = { start_date: OperationChecks::SentDate.new(fields["startDate"], start_message),
                end_date: OperationChecks::SentDate.new(fields["endDate"], END_DATE) }
      check_dates(Event, dates.select { |_, date| date.value })
    end
  end
end
