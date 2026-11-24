module ChroniclerMcp
  module CharacterTools
    extend ToolSet

    def self.character_id(input, field = "id") = RecordId.parse(input[field], "character")

    tool("list_characters", :read, "List all characters with their group memberships", {
           name: text("Filter by name (case-insensitive partial match)"),
           groupId: id("Filter to characters belonging to this group ID"),
           birthYear: id("Filter to characters born in this year")
         }) do |input|
      CharacterOperations.list(name: input["name"], group_id: input["groupId"], birth_year: input["birthYear"])
    end

    tool("find_placeholder_characters", :read,
         "Find characters with a placeholder birth date (default: 2200-01-01)", {
           birthDate: date("Placeholder birth date to match (YYYY-MM-DD); defaults to 2200-01-01")
         }) { |input| CharacterOperations.placeholders(input["birthDate"]) }

    tool("get_character", :read, "Get a single character by ID",
         { id: id("Character ID") }, required: ["id"]) { |input| CharacterOperations.show(character_id(input)) }

    tool("get_character_events", :read, "Get all events for a character, ordered chronologically",
         { id: id("Character ID") }, required: ["id"]) { |input| CharacterOperations.events(character_id(input)) }

    tool("create_character", :write, "Create a new character", {
           name: label("Character name"),
           birthDate: date("Birth date (YYYY-MM-DD)"),
           deathDate: date("Death date (YYYY-MM-DD), omit if alive"),
           groupIds: ids("Group IDs to assign this character to")
         }, required: %w[name birthDate]) { |input| CharacterOperations.create(input) }

    tool("update_character", :write, "Update an existing character", {
           id: id("Character ID"),
           name: label("New name"),
           birthDate: date("New birth date (YYYY-MM-DD)"),
           deathDate: nullable_date("New death date (YYYY-MM-DD), or null to clear"),
           groupIds: ids("Full replacement list of group IDs (replaces existing)")
         }, required: ["id"]) { |input| CharacterOperations.update(character_id(input), input.except("id")) }

    tool("bulk_update_characters", :write, "Update multiple characters in a single transaction", {
           updates: {
             type: "array", minItems: 1, description: "List of character updates to apply",
             items: object({ id: id("Character ID"), name: label("New name"),
                             birthDate: date("New birth date (YYYY-MM-DD)"),
                             deathDate: nullable_date("New death date (YYYY-MM-DD), or null to clear"),
                             groupIds: ids("Full replacement list of group IDs") }, ["id"])
           }
         }, required: ["updates"]) { |input| BulkCharacterOperation.update(input) }

    tool("delete_character", :delete, "Delete a character by ID",
         { id: id("Character ID") }, required: ["id"]) { |input| CharacterOperations.delete(character_id(input)) }

    tool("add_group_to_character", :write, "Add a single group membership to a character", {
           characterId: id("Character ID"),
           groupId: id("Group ID to add")
         }, required: %w[characterId groupId]) do |input|
      CharacterOperations.add_group(character_id(input, "characterId"), input)
    end

    tool("remove_group_from_character", :write, "Remove a single group membership from a character", {
           characterId: id("Character ID"),
           groupId: id("Group ID to remove")
         }, required: %w[characterId groupId]) do |input|
      CharacterOperations.remove_group(character_id(input, "characterId"), RecordId.parse(input["groupId"], "group"))
    end
  end
end
