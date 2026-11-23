class UniverseSetting < ApplicationRecord
  include TrimmedName

  DEFAULTS = { name: "My Universe", start_date: "0001-01-01", end_date: "1000-12-31", current_day: "0500-06-15" }.freeze

  validates :start_date, :end_date, :current_day, presence: true, calendar_date: true

  # The API has always accepted any day.
  validate :current_day_within_universe, on: :form

  after_update :move_current_day_event, if: :saved_change_to_current_day?

  def self.current
    order(:id).first
  end

  # The settings, created with their Current Day event if either is missing.
  def self.current!
    transaction do
      setting = current || create!(DEFAULTS)
      unless Event.exists?(is_current_day: true)
        Event.create!(name: "Current Day", start_date: setting.current_day, is_current_day: true)
      end
      setting
    end
  end

  private

  def current_day_within_universe
    return unless [start_date, end_date, current_day].all? { |date| CalendarDate.valid?(date) }

    errors.add(:current_day, :before_universe, limit: start_date) if current_day < start_date
    errors.add(:current_day, :after_universe, limit: end_date) if current_day > end_date
  end

  # The event follows the setting even if the universe's bounds or its members would refuse the day.
  def move_current_day_event
    Event.where(is_current_day: true).find_each do |event|
      end_date = event.end_date && CalendarDate.shift(current_day, event.length_in_days)
      # rubocop:disable-next Rails/SkipsModelValidations
      event.update_columns(start_date: current_day, end_date:, updated_at: Time.current)
    end
  end
end
