module Api
  class BaseController < ActionController::API
    DATE_ERRORS = %i[invalid_date before_universe after_universe].freeze

    # A date as sent, with the message for one that is malformed or impossible.
    SentDate = Data.define(:value, :message)

    rescue_from StandardError do |error|
      Rails.logger.error(error.full_message(highlight: false))
      render_json({ error: "Internal server error" }, :internal_server_error)
    end

    rescue_from Rejection do |rejection|
      render_json({ error: rejection.message }, rejection.status)
    end

    before_action :authorize

    private

    def authorize
      key = Rails.configuration.x.api_key
      return if key.nil?

      token = request.headers["Authorization"].to_s[/\ABearer (.*)\z/m, 1].to_s
      reject("Unauthorized", :unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(token, key)
    end

    def render_json(value, status = :ok)
      render(json: JSON.generate(value), status:)
      # Without the charset that Rails adds, which JSON does not have.
      response.headers["Content-Type"] = "application/json"
    end

    def reject(message, status = :bad_request)
      raise Rejection.new(message, status)
    end

    # The body's fields. A key that was not sent is absent, unlike one sent as null.
    def body
      @body ||= begin
        text = request.raw_post.dup.force_encoding(Encoding::UTF_8)
        parsed = text.empty? ? nil : JSON.parse(text)
        parsed.is_a?(Hash) ? parsed : {}
      end
    end

    # Query parameters as strings. One sent twice counts as absent.
    def query(name)
      parameters = Rack::Utils.parse_query(request.query_string)
      return unless parameters.key?(name)

      value = parameters[name]
      value.to_s unless value.is_a?(Array)
    end

    # As JavaScript's parseInt does, with nil for what is not a number, and for 0, which filters ignore.
    def query_integer(name)
      integer = leading_integer(query(name).to_s)
      integer unless integer&.zero?
    end

    def leading_integer(text)
      integer = text[/\A\s*([+-]?\d+)/, 1]&.to_i
      raise RangeError, "#{integer} is out of range" if integer && integer.abs > StagedMembers::MAX_ID

      integer
    end

    def path_id(name, label)
      id = params[name].to_s
      id = id.match?(/\A\d+\z/) ? StagedMembers.parse_id(id) : nil
      id || reject("Invalid #{label} ID")
    end

    def find(scope, id)
      scope.find_by(id:) || reject("#{scope.model_name.human} not found", :not_found)
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

        reject(ErrorMessage.for(error, field: labels[attribute]))
      end
    end

    # Saves, marking the record as updated even if no field changes.
    def save(record, prefix = "")
      record.updated_at = Time.current
      return if record.save

      error = record.errors.find { |found| ErrorMessage::TEMPLATES.key?(found.type) }
      raise ActiveRecord::RecordInvalid, record if error.nil? || record.errors.any? { |found| found.type == :too_long }

      reject(prefix + ErrorMessage.for(error))
    end
  end
end
