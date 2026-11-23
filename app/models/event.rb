class Event < ApplicationRecord
  has_many :event_characters, dependent: :delete_all
  has_many :characters, through: :event_characters
end
