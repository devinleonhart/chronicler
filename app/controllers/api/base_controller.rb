module Api
  class BaseController < ActionController::API
    include ActionController::ContentSecurityPolicy

    # The policy is for pages, and its nonce would start a session.
    content_security_policy false

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
      return if ActiveSupport::SecurityUtils.secure_compare(token, key)

      raise Rejection.new("Unauthorized", :unauthorized)
    end

    def render_json(value, status = :ok)
      render(json: JSON.generate(value), status:)
      # Without the charset that Rails adds, which JSON does not have.
      response.headers["Content-Type"] = "application/json"
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
      text[/\A\s*([+-]?\d+)/, 1]&.to_i
    end

    def path_id(name, label)
      RecordId.parse(params[name], label)
    end
  end
end
