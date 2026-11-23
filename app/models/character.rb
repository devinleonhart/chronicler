class Character < ApplicationRecord
  include TrimmedName
  include StagedMembers

  has_many :character_groups, dependent: :delete_all
  has_many :groups, through: :character_groups
  has_many :event_characters, dependent: :delete_all
  has_many :events, through: :event_characters

  stages_members :groups
  normalizes :death_date, with: :presence.to_proc

  validates :birth_date, presence: true
  validates :birth_date, :death_date, calendar_date: true, universe_bounds: true
  validate :death_not_before_birth, if: -> { birth_date_changed? || death_date_changed? }

  scope :by_name, -> { order(:name, :id) }
  scope :name_contains, ->(text) { where("characters.name ILIKE ?", "%#{text}%") }
  scope :born_in, ->(year) { where("birth_date LIKE ?", "#{year}-%") }
  scope :in_group, ->(id) { where(id: CharacterGroup.where(group_id: id).select(:character_id)) }

  def add_group(group)
    character_groups.find_or_create_by!(group:)
  end

  private

  def death_not_before_birth
    errors.add(:death_date, :before_birth) if birth_date && death_date && death_date < birth_date
  end
end
