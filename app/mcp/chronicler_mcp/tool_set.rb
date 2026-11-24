module ChroniclerMcp
  # Defines tools. A tool's block gets the known arguments, with JSON names, and gives data
  # or text. Errors come back as the API words them.
  module ToolSet
    Tool = Data.define(:name, :scope, :definition)

    DATE_PATTERN = '^\d{4}-\d{2}-\d{2}$'.freeze
    FAILURE = "Internal server error".freeze

    def tools
      @tools ||= []
    end

    def tool(name, scope, description, properties = {}, required: [], &block)
      known = properties.keys
      definition = MCP::Tool.define(
        name:, description:, annotations: annotations_for(scope), input_schema: object(properties, required)
      ) do |server_context: nil, **arguments| # rubocop:disable Lint/UnusedBlockArgument
        fields = arguments.slice(*known).deep_stringify_keys
        scope == :delete ? ToolSet.deletion { block.call(fields) } : ToolSet.answer { block.call(fields) }
      end
      tools << Tool.new(name:, scope:, definition:)
    end

    def annotations_for(scope)
      { read_only_hint: scope == :read, destructive_hint: scope == :delete, open_world_hint: false }
    end

    def id(description) = { type: "integer", exclusiveMinimum: 0, description: }
    def text(description) = { type: "string", description: }
    def label(description) = { type: "string", minLength: 1, description: }
    def date(description) = { type: "string", pattern: DATE_PATTERN, description: }
    def nullable_text(description) = { type: %w[string null], description: }

    def nullable_date(description)
      { anyOf: [{ type: "string", pattern: DATE_PATTERN }, { type: "null" }], description: }
    end

    def ids(description, **)
      { type: "array", items: { type: "integer", exclusiveMinimum: 0 }, description:, ** }
    end

    def object(properties, required)
      schema = { type: "object", properties: }
      required.empty? ? schema : schema.merge(required:)
    end

    class << self
      def answer
        data = yield
        response(data.is_a?(String) ? data : JSON.pretty_generate(data))
      rescue Rejection => error
        response(JSON.pretty_generate(error: error.message), error: true)
      rescue StandardError => error
        log(error)
        response(JSON.pretty_generate(error: FAILURE), error: true)
      end

      # Deletions tell only whether they succeeded.
      def deletion
        yield
        response(JSON.pretty_generate(success: true, status: 204))
      rescue Rejection => error
        response(JSON.pretty_generate(success: false, status: error.status_code), error: true)
      rescue StandardError => error
        log(error)
        response(JSON.pretty_generate(success: false, status: 500), error: true)
      end

      private

      def response(text, error: false)
        MCP::Tool::Response.new([{ type: "text", text: }], error:)
      end

      # An error's message may hold what was sent.
      def log(error)
        Rails.logger.error("mcp tool failed: #{error.class} at #{error.backtrace&.first}")
      end
    end
  end
end
