class EventCharacter < ApplicationRecord
  self.primary_key = [:event_id, :character_id]

  belongs_to :event
  belongs_to :character
end
