class Character < ApplicationRecord
  has_many :character_groups, dependent: :delete_all
  has_many :groups, through: :character_groups
  has_many :event_characters, dependent: :delete_all
  has_many :events, through: :event_characters
end
