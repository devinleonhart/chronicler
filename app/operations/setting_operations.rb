module SettingOperations
  extend OperationChecks

  DATES = { "startDate" => :start_date, "endDate" => :end_date, "currentDay" => :current_day }.freeze

  def self.show
    Api::JsonRecord.setting(UniverseSetting.current!)
  end

  def self.update(fields)
    check_fields(fields)
    setting = UniverseSetting.current || reject("Settings not found", :not_found)
    setting.assign_attributes(fields.slice("name"))
    setting.assign_attributes(sent_dates(fields).transform_values(&:value))
    # Sending the same day again still moves the event to it.
    setting.current_day_will_change! if fields.key?("currentDay")
    save(setting)
    Api::JsonRecord.setting(setting)
  end

  def self.check_fields(fields)
    check_name(fields["name"], "Name must be a non-empty string") if fields.key?("name")
    dates = sent_dates(fields)
    dates.each_value { |date| check_date(date.value, date.message) }
    check_dates(UniverseSetting, dates)
  end
  private_class_method :check_fields

  def self.sent_dates(fields)
    DATES.filter_map do |field, attribute|
      next unless fields.key?(field)

      [attribute, OperationChecks::SentDate.new(fields[field], "#{field} must be a valid date string (YYYY-MM-DD)")]
    end.to_h
  end
  private_class_method :sent_dates
end
