module Api
  class EventCharactersController < EventsController
    def create
      id = path_id(:id, "event")
      character_id = body["characterId"]
      reject("characterId must be a positive integer") unless positive_integer?(character_id)

      event = find(Event, id)
      reject(ErrorMessage.for(event.errors.first)) unless event.add_character(character_id.to_i)
      render_event id
    end

    def destroy
      id = path_id(:id, "event")
      character_id = path_id(:character_id, "character")
      find(Event, id).event_characters.where(character_id:).delete_all
      render_event id
    end
  end
end
