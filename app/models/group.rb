class Group < ApplicationRecord
  include TrimmedName

  has_many :character_groups, dependent: :delete_all
  has_many :characters, through: :character_groups

  scope :by_name, -> { order(:name, :id) }
end
