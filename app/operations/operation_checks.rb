# What the operations have in common. Fields have their JSON names; one that was not sent
# is absent, unlike one sent as null.
module OperationChecks
  DATE_ERRORS = %i[invalid_date before_universe after_universe].freeze

  # A date as sent, with the message for one that is malformed or impossible.
  SentDate = Data.define(:value, :message)

  private

  def reject(message, status = :bad_request)
    raise Rejection.new(message, status)
  end

  def find(scope, id)
    scope.find_by(id:) || reject("#{scope.model_name.human} not found", :not_found)
  end

  # Ids and years beyond a database integer are an unexpected error, as they always were.
  def in_range(integer)
    raise RangeError, "#{integer} is out of range" if integer && integer.abs > StagedMembers::MAX_ID

    integer
  end

  def check_name(value, message)
    reject(message) unless value.is_a?(String) && TrimmedName.trim(value).present?
  end

  def check_date(value, message)
    reject(message) unless CalendarDate.formatted?(value)
  end

  def check_list(value, message)
    reject(message) unless value.is_a?(Array)
  end

  def positive_integer?(value)
    case value
    when Integer then value.positive?
    when Float then value.finite? && value.positive? && value == value.to_i
    end
  end

  # Checks dates as if new, since a date that is sent is checked even when it does not change.
  def check_dates(model, dates, labels = {})
    probe = model.new(dates.transform_values(&:value))
    probe.validate
    dates.each do |attribute, date|
      error = probe.errors.where(attribute).find { |found| DATE_ERRORS.include?(found.type) } or next
      reject(date.message) if error.type == :invalid_date

      reject(Api::ErrorMessage.for(error, field: labels[attribute]))
    end
  end

  # Saves, marking the record as updated even if no field changes.
  def save(record, prefix = "")
    record.updated_at = Time.current
    return if record.save

    error = record.errors.find { |found| Api::ErrorMessage::TEMPLATES.key?(found.type) }
    raise ActiveRecord::RecordInvalid, record if error.nil? || record.errors.any? { |found| found.type == :too_long }

    reject(prefix + Api::ErrorMessage.for(error))
  end

  # The attributes of the fields that were sent.
  def attributes(fields, names)
    names.filter_map { |field, attribute| [attribute, fields[field]] if fields.key?(field) }.to_h
  end
end
