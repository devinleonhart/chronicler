module ChroniclerMcp
  module UniverseTools
    extend ToolSet

    tool("get_settings", :read, "Get universe settings (name, date bounds, current day)") { SettingOperations.show }

    tool("update_settings", :write, "Update universe settings", {
           name: label("Universe name"),
           startDate: date("Universe start date (YYYY-MM-DD)"),
           endDate: date("Universe end date (YYYY-MM-DD)"),
           currentDay: date("Current day reference date (YYYY-MM-DD); also updates the Current Day event")
         }) { |input| SettingOperations.update(input) }

    tool("get_summary", :read, "Generate a plain-text narrative summary of events for one or more characters", {
           characterIds: ids("Character IDs to include in the summary", minItems: 1)
         }, required: ["characterIds"]) { |input| SummaryOperation.text(input["characterIds"]) }
  end
end
