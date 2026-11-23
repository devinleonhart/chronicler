# API controllers read the raw body themselves: its types must reach them unchanged, and a
# malformed one must give the API's own error, which Rails would preempt with its page.
Rails.application.config.to_prepare do
  ActionDispatch::Request.parameter_parsers = ActionDispatch::Request.parameter_parsers.except(:json)
end
