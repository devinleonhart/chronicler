require "simplecov"

SimpleCov.start "rails" do
  skip "/spec/"
  enable_coverage :branch
  cover "{app,lib}/**/*.rb"

  # Only bin/ci runs every spec, so only it can be held to the minimum.
  minimum_coverage line: 90 if ENV["CI"]
end

ENV["RAILS_ENV"] = "test" if ENV["RAILS_ENV"].to_s != "test"
require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"

Rails.application.reload_routes!
Rails.root.glob("spec/support/**/*.rb").each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => error
  puts error.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures").to_s]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
