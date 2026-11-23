module Api
  class GroupsController < BaseController
    def index
      render_json(groups.by_name.map { |group| JsonRecord.group(group) })
    end

    def show
      render_group path_id(:id, "group")
    end

    def create
      check_name(body["name"], "Group name is required")
      check_description
      group = Group.new(body.slice("name", "description"))
      save(group)
      render_group group.id, :created
    end

    def update
      id = path_id(:id, "group")
      check_name(body["name"], "Group name is required") if body.key?("name")
      check_description
      group = find(Group, id)
      group.assign_attributes(body.slice("name", "description"))
      save(group)
      render_group id
    end

    def destroy
      find(Group, path_id(:id, "group")).destroy!
      head :no_content
    end

    private

    def groups
      Group.includes(character_groups: :character)
    end

    def render_group(id, status = :ok)
      render_json JsonRecord.group(find(groups, id)), status
    end

    def check_description
      description = body["description"]
      reject("Description must be a string or null") unless description.nil? || description.is_a?(String)
    end
  end
end
