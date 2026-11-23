class Event < ApplicationRecord
  include TrimmedName
  include StagedMembers

  has_many :event_characters, dependent: :delete_all
  has_many :characters, through: :event_characters

  stages_members :characters
  normalizes :end_date, with: :presence.to_proc

  validates :start_date, presence: true
  validates :start_date, :end_date, calendar_date: true, universe_bounds: true
  validate :end_not_before_start, if: :dates_changed?
  validate :members_alive, if: -> { dates_changed? || members_changed? }

  before_destroy :keep_current_day, prepend: true

  scope :chronological, -> { order(:start_date, :id) }
  scope :name_contains, ->(text) { where("events.name ILIKE ?", "%#{text}%") }
  scope :starting_from, ->(date) { where(start_date: date..) }
  scope :starting_until, ->(date) { where(start_date: ..date) }
  scope :with_character, ->(id) { where(id: EventCharacter.where(character_id: id).select(:event_id)) }

  # Checks only the added character, so that a member already in violation does not block others.
  def add_character(id) # rubocop:disable Naming/PredicateMethod
    errors.clear
    character = Character.find_by(id: StagedMembers.parse_id(id))
    character ? check_alive(character) : errors.add(:characters, :unknown, ids: id.to_s)
    return false if errors.any?

    event_characters.find_or_create_by!(character:)
    true
  end

  # 0 without an end date, or with one before the start.
  def length_in_days
    end_date ? [CalendarDate.days_between(start_date, end_date), 0].max : 0
  end

  private

  def dates_changed?
    start_date_changed? || end_date_changed?
  end

  def members_changed?
    return true if new_record?

    ids = staged_ids(:characters)
    !ids.nil? && ids.sort != event_characters.pluck(:character_id).sort
  end

  def end_not_before_start
    errors.add(:end_date, :before_start) if start_date && end_date && end_date < start_date
  end

  def members_alive
    return if start_date.blank?

    ids = staged_ids(:characters)
    members = ids ? Character.where(id: ids) : characters
    members.sort_by(&:id).each { |character| check_alive(character) }
  end

  def check_alive(character)
    last_day = end_date || start_date
    if character.birth_date > last_day
      errors.add(:characters, :unborn, name: character.name, date: character.birth_date, limit: last_day)
    elsif character.death_date && character.death_date < start_date
      errors.add(:characters, :dead, name: character.name, date: character.death_date, limit: start_date)
    end
  end

  def keep_current_day
    return unless is_current_day

    errors.add(:base, :current_day)
    throw :abort
  end
end
