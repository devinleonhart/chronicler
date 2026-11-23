Rails.application.configure do
  config.x.api_key = ENV["API_KEY"].presence

  # SECRET_KEY_BASE_DUMMY marks an image build, which precompiles assets without secrets.
  if Rails.env.production? && config.x.api_key.nil? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
    raise "API_KEY must be set in production"
  end
end
