class CalendarDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || CalendarDate.valid?(value)

    record.errors.add(attribute, :invalid_date)
  end
end
