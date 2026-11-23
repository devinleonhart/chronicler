module Api
  # Ends a request with an error message.
  class Rejection < StandardError
    attr_reader :status

    def initialize(message, status = :bad_request)
      super(message)
      @status = status
    end
  end
end
