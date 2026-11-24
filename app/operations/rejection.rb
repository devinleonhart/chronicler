# Ends an operation with an error message, and the HTTP status that goes with it.
class Rejection < StandardError
  attr_reader :status

  def initialize(message, status = :bad_request)
    super(message)
    @status = status
  end

  def status_code
    Rack::Utils.status_code(status)
  end
end
