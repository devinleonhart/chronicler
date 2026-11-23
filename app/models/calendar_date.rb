# Dates are YYYY-MM-DD strings, because Ruby's default calendar is Julian before 1582.
module CalendarDate
  FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  def self.formatted?(value)
    value.is_a?(String) && value.match?(FORMAT)
  end

  def self.valid?(value)
    formatted?(value) && Date.valid_civil?(*value.split("-").map(&:to_i), Date::GREGORIAN)
  end

  def self.shift(value, days)
    (parse(value) + days).iso8601
  end

  def self.days_between(first, last)
    (parse(last) - parse(first)).to_i
  end

  def self.parse(value)
    Date.civil(*value.split("-").map(&:to_i), Date::GREGORIAN)
  end
  private_class_method :parse
end
