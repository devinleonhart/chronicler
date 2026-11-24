module ChroniclerMcp
  module GroupTools
    extend ToolSet

    def self.group_id(input) = RecordId.parse(input["id"], "group")

    tool("list_groups", :read, "List all groups with their members") { GroupOperations.list }

    tool("get_group", :read, "Get a single group by ID",
         { id: id("Group ID") }, required: ["id"]) { |input| GroupOperations.show(group_id(input)) }

    tool("create_group", :write, "Create a new group", {
           name: label("Group name"),
           description: nullable_text("Optional description")
         }, required: ["name"]) { |input| GroupOperations.create(input) }

    tool("update_group", :write, "Update an existing group", {
           id: id("Group ID"),
           name: label("New name"),
           description: nullable_text("New description, or null to clear")
         }, required: ["id"]) { |input| GroupOperations.update(group_id(input), input.except("id")) }

    tool("delete_group", :delete, "Delete a group by ID (does not delete its members)",
         { id: id("Group ID") }, required: ["id"]) { |input| GroupOperations.delete(group_id(input)) }
  end
end
