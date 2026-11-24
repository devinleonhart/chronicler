module Api
  class CharactersController < BaseController
    def index
      render_json CharacterOperations.list(name: query("name"), birth_year: query_integer("birthYear"),
                                           group_id: query_integer("groupId"))
    end

    def placeholders
      render_json CharacterOperations.placeholders(query("birthDate"))
    end

    def events
      render_json CharacterOperations.events(id)
    end

    def show
      render_json CharacterOperations.show(id)
    end

    def create
      render_json CharacterOperations.create(body), :created
    end

    def update
      render_json CharacterOperations.update(id, body)
    end

    def bulk
      render_json BulkCharacterOperation.update(body)
    end

    def destroy
      CharacterOperations.delete(id)
      head :no_content
    end

    private

    def id
      path_id(:id, "character")
    end
  end
end
