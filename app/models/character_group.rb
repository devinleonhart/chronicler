class CharacterGroup < ApplicationRecord
  self.primary_key = [:character_id, :group_id]

  belongs_to :character
  belongs_to :group
end
