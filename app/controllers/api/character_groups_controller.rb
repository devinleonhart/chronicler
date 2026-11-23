module Api
  class CharacterGroupsController < CharactersController
    def create
      id = path_id(:id, "character")
      group_id = body["groupId"]
      reject("groupId must be a positive integer") unless positive_integer?(group_id)

      character = find(Character, id)
      raise RangeError, "groupId is out of range" if group_id > StagedMembers::MAX_ID

      character.add_group(find(Group, group_id.to_i))
      render_character id
    end

    def destroy
      id = path_id(:id, "character")
      group_id = path_id(:group_id, "group")
      find(Character, id).character_groups.where(group_id:).delete_all
      render_character id
    end
  end
end
