module Api
  class EventsController < BaseController
    def index
      render_json EventOperations.list(name: query("name"), start_after: query("startAfter"),
                                       start_before: query("startBefore"), character_id: query_integer("characterId"))
    end

    def show
      render_json EventOperations.show(id)
    end

    def create
      render_json EventOperations.create(body), :created
    end

    def update
      render_json EventOperations.update(id, body)
    end

    def destroy
      EventOperations.delete(id)
      head :no_content
    end

    private

    def id
      path_id(:id, "event")
    end
  end
end
