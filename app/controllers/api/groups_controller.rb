module Api
  class GroupsController < BaseController
    def index
      render_json GroupOperations.list
    end

    def show
      render_json GroupOperations.show(id)
    end

    def create
      render_json GroupOperations.create(body), :created
    end

    def update
      render_json GroupOperations.update(id, body)
    end

    def destroy
      GroupOperations.delete(id)
      head :no_content
    end

    private

    def id
      path_id(:id, "group")
    end
  end
end
