class Group < ApplicationRecord
  has_many :character_groups, dependent: :delete_all
  has_many :characters, through: :character_groups
end
