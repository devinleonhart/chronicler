module Api
  # The API's wording for a model's error. Fields have their JSON names.
  module ErrorMessage
    TEMPLATES = {
      before_universe: "%<field>s cannot be before the universe start date (%<limit>s)",
      after_universe: "%<field>s cannot be after the universe end date (%<limit>s)",
      before_birth: "deathDate cannot be before birthDate",
      before_start: "endDate cannot be before startDate",
      unknown: "%<field>s not found: %<ids>s",
      unborn: 'Character "%<name>s" was not yet born when this event ended (born %<date>s, event ends %<limit>s)',
      dead: 'Character "%<name>s" had already died before this event started (died %<date>s, event starts %<limit>s)',
      current_day: "Cannot delete the Current Day event"
    }.freeze

    def self.for(error, field: nil)
      field ||= error.type == :unknown ? error.attribute.to_s.capitalize : error.attribute.to_s.camelize(:lower)
      format(TEMPLATES.fetch(error.type), field:, **error.options.slice(:limit, :ids, :name, :date))
    end
  end
end
