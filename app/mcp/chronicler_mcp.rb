# The MCP server: the API's operations, as tools.
module ChroniclerMcp
  # The sets are loaded here, so that the list does not depend on loading order.
  def self.tool_sets
    [CharacterTools, GroupTools, EventTools, UniverseTools]
  end
end
