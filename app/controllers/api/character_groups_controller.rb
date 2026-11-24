module Api
  class CharacterGroupsController < BaseController
    def create
      render_json CharacterOperations.add_group(path_id(:id, "character"), body)
    end

    def destroy
      render_json CharacterOperations.remove_group(path_id(:id, "character"), path_id(:group_id, "group"))
    end
  end
end
