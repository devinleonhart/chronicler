module Api
  class SettingsController < BaseController
    DATES = { "startDate" => :start_date, "endDate" => :end_date, "currentDay" => :current_day }.freeze

    def show
      render_json JsonRecord.setting(UniverseSetting.current!)
    end

    def update
      check_fields
      setting = UniverseSetting.current || reject("Settings not found", :not_found)
      setting.assign_attributes(body.slice("name"))
      setting.assign_attributes(sent_dates.transform_values(&:value))
      # Sending the same day again still moves the event to it.
      setting.current_day_will_change! if body.key?("currentDay")
      save(setting)
      render_json JsonRecord.setting(setting)
    end

    private

    def check_fields
      check_name(body["name"], "Name must be a non-empty string") if body.key?("name")
      sent_dates.each_value { |date| check_date(date.value, date.message) }
      check_dates(UniverseSetting, sent_dates)
    end

    def sent_dates
      DATES.filter_map do |field, attribute|
        next unless body.key?(field)

        [attribute, SentDate.new(body[field], "#{field} must be a valid date string (YYYY-MM-DD)")]
      end.to_h
    end
  end
end
