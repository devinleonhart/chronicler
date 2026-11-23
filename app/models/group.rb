class Group < ApplicationRecord
  include TrimmedName

  has_many :character_groups, dependent: :delete_all
  has_many :characters, through: :character_groups

  scope :by_name, -> { order(:name, :id) }
  scope :matching, lambda { |text|
    pattern = "%#{sanitize_sql_like(text)}%"
    where("groups.name ILIKE :pattern OR groups.description ILIKE :pattern", pattern:)
  }
end
