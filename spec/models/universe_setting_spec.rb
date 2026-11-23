require "rails_helper"

RSpec.describe UniverseSetting do
  it "stores its dates as written" do
    setting = create(:universe_setting, start_date: "1000-01-01")

    expect(setting.reload).to have_attributes(start_date: "1000-01-01", current_day: "2300-09-25")
  end

  it "trims and requires a name" do
    expect(build(:universe_setting, name: " \u00a0Name\u3000").name).to eq("Name")
    expect(build(:universe_setting, name: " ")).not_to be_valid
    expect(build(:universe_setting, name: "x" * 256)).not_to be_valid
  end

  it "refuses impossible dates" do
    %i[start_date end_date current_day].each do |attribute|
      setting = build(:universe_setting, attribute => "2300-02-31")

      expect(setting).not_to be_valid
      expect(setting.errors).to be_of_kind(attribute, :invalid_date)
    end
  end

  describe ".current!" do
    it "creates the defaults and the Current Day event" do
      setting = described_class.current!

      expect(setting).to have_attributes(name: "My Universe", end_date: "1000-12-31", current_day: "0500-06-15")
      expect(Event.sole).to have_attributes(is_current_day: true, start_date: "0500-06-15", end_date: nil)
    end

    it "adds a missing Current Day event once" do
      create(:universe_setting)
      2.times { described_class.current! }

      expect(described_class.count).to eq(1)
      expect(Event.sole).to have_attributes(is_current_day: true, start_date: "2300-09-25")
    end

    it "creates neither when the event cannot be created" do
      allow(Event).to receive(:create!).and_raise(ActiveRecord::StatementInvalid)

      expect { described_class.current! }.to raise_error(ActiveRecord::StatementInvalid)
      expect(described_class.count).to eq(0)
    end
  end

  describe "moving the Current Day" do
    let(:setting) { create(:universe_setting) }
    let!(:event) { create(:event, start_date: "2300-09-25", is_current_day: true) }
    let!(:other) { create(:event, start_date: "2300-09-25") }

    it "moves only the Current Day event" do
      setting.update!(current_day: "2301-01-01")

      expect(event.reload.start_date).to eq("2301-01-01")
      expect(other.reload.start_date).to eq("2300-09-25")
    end

    it "moves the end date with the start, keeping the length" do
      { "2300-09-25" => "2301-01-01", "2300-09-28" => "2301-01-04", nil => nil }.each do |old_end, new_end|
        setting.update!(current_day: "2300-09-25")
        event.reload.update!(start_date: "2300-09-25", end_date: old_end)

        setting.update!(current_day: "2301-01-01")

        expect(event.reload).to have_attributes(start_date: "2301-01-01", end_date: new_end)
      end
    end

    it "repairs an end date before the start" do
      event.update_columns(end_date: "2300-09-01") # rubocop:disable Rails/SkipsModelValidations
      setting.update!(current_day: "2301-01-01")

      expect(event.reload.end_date).to eq("2301-01-01")
    end

    it "counts days in the Gregorian calendar" do
      event.update!(start_date: "1500-02-28", end_date: "1500-03-01")
      setting.update!(current_day: "1582-10-05")

      expect(event.reload.end_date).to eq("1582-10-06")
    end

    it "keeps the old day when the event cannot be moved" do
      setting
      allow(Event).to receive(:where).and_raise(ActiveRecord::StatementInvalid)

      expect { setting.update!(current_day: "2301-01-01") }.to raise_error(ActiveRecord::StatementInvalid)
      expect(setting.reload.current_day).to eq("2300-09-25")
    end
  end
end
