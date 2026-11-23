module Api
  class EventsController < BaseController
    START_REQUIRED = "startDate is required and must be a valid date string (YYYY-MM-DD)".freeze
    START = "startDate must be a valid date string (YYYY-MM-DD)".freeze
    END_DATE = "endDate must be a valid date string (YYYY-MM-DD) or null".freeze

    def index
      scope = events.chronological
      scope = scope.name_contains(query("name")) if query("name").present?
      scope = scope.starting_from(query("startAfter")) if query("startAfter").present?
      scope = scope.starting_until(query("startBefore")) if query("startBefore").present?
      scope = scope.with_character(query_integer("characterId")) if query_integer("characterId")
      render_json(scope.map { |event| JsonRecord.event(event) })
    end

    def show
      render_event path_id(:id, "event")
    end

    def create
      check_name(body["name"], "Event name is required")
      check_fields(START_REQUIRED, start_required: true)
      event = Event.new(attributes)
      save(event)
      render_event event.id, :created
    end

    def update
      id = path_id(:id, "event")
      check_name(body["name"], "Event name is required") if body.key?("name")
      check_fields(START)
      event = find(Event, id)
      event.assign_attributes(attributes)
      save(event)
      render_event id
    end

    def destroy
      event = find(Event, path_id(:id, "event"))
      return head(:no_content) if event.destroy

      reject(ErrorMessage.for(event.errors.first))
    end

    private

    def events
      Event.includes(event_characters: :character)
    end

    def render_event(id, status = :ok)
      render_json JsonRecord.event(find(events, id)), status
    end

    def check_fields(start_message, start_required: false)
      check_date(body["startDate"], start_message) if start_required || body.key?("startDate")
      check_date(body["endDate"], END_DATE) unless body["endDate"].nil?
      check_list(body["characterIds"], "characterIds must be an array") if body.key?("characterIds")
      dates = { start_date: SentDate.new(body["startDate"], start_message),
                end_date: SentDate.new(body["endDate"], END_DATE) }
      check_dates(Event, dates.select { |_, date| date.value })
    end

    def attributes
      { "name" => :name, "startDate" => :start_date, "endDate" => :end_date, "characterIds" => :character_ids }
        .filter_map { |field, attribute| [attribute, body[field]] if body.key?(field) }.to_h
    end
  end
end
