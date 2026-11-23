require "capybara/cuprite"

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # The container runs as root with a small /dev/shm, neither of which Chromium's defaults allow.
    driven_by :cuprite, screen_size: [1280, 900], options: {
      browser_options: { "no-sandbox" => nil, "disable-dev-shm-usage" => nil },
      process_timeout: 30,
      js_errors: true
    }
  end
end
