module Api
  class EventCharactersController < BaseController
    def create
      render_json EventOperations.add_character(path_id(:id, "event"), body)
    end

    def destroy
      render_json EventOperations.remove_character(path_id(:id, "event"), path_id(:character_id, "character"))
    end
  end
end
