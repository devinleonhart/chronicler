require "rails_helper"

RSpec.describe UniverseSetting do
  it "stores its dates as written" do
    setting = create(:universe_setting, start_date: "1000-01-01")

    expect(setting.reload).to have_attributes(start_date: "1000-01-01", current_day: "2300-09-25")
  end
end
