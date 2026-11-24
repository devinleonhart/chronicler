module ChroniclerMcp
  module EventTools
    extend ToolSet

    def self.event_id(input, field = "id") = RecordId.parse(input[field], "event")

    tool("list_events", :read, "List all events with their characters", {
           name: text("Filter by name (case-insensitive partial match)"),
           characterId: id("Filter to events featuring this character ID"),
           startAfter: date("Filter to events starting on or after this date (YYYY-MM-DD)"),
           startBefore: date("Filter to events starting on or before this date (YYYY-MM-DD)")
         }) do |input|
      EventOperations.list(name: input["name"], character_id: input["characterId"],
                           start_after: input["startAfter"], start_before: input["startBefore"])
    end

    tool("get_event", :read, "Get a single event by ID",
         { id: id("Event ID") }, required: ["id"]) { |input| EventOperations.show(event_id(input)) }

    tool("create_event", :write, "Create a new event", {
           name: label("Event name"),
           startDate: date("Start date (YYYY-MM-DD)"),
           endDate: nullable_date("End date (YYYY-MM-DD), omit for single-day events"),
           characterIds: ids("Character IDs to attach to this event")
         }, required: %w[name startDate]) { |input| EventOperations.create(input) }

    tool("update_event", :write, "Update an existing event", {
           id: id("Event ID"),
           name: label("New name"),
           startDate: date("New start date (YYYY-MM-DD)"),
           endDate: nullable_date("New end date (YYYY-MM-DD), or null to clear"),
           characterIds: ids("Full replacement list of character IDs (replaces existing)")
         }, required: ["id"]) { |input| EventOperations.update(event_id(input), input.except("id")) }

    tool("add_character_to_event", :write, "Add a single character to an existing event", {
           eventId: id("Event ID"),
           characterId: id("Character ID to add")
         }, required: %w[eventId characterId]) do |input|
      EventOperations.add_character(event_id(input, "eventId"), input)
    end

    tool("remove_character_from_event", :write, "Remove a single character from an existing event", {
           eventId: id("Event ID"),
           characterId: id("Character ID to remove")
         }, required: %w[eventId characterId]) do |input|
      EventOperations.remove_character(event_id(input, "eventId"), RecordId.parse(input["characterId"], "character"))
    end

    tool("delete_event", :delete, "Delete an event by ID (cannot delete the Current Day event)",
         { id: id("Event ID") }, required: ["id"]) { |input| EventOperations.delete(event_id(input)) }
  end
end
