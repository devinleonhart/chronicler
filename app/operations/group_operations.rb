module GroupOperations
  extend OperationChecks

  def self.list
    groups.by_name.map { |group| Api::JsonRecord.group(group) }
  end

  def self.show(id)
    Api::JsonRecord.group(find(groups, id))
  end

  def self.create(fields)
    check_name(fields["name"], "Group name is required")
    check_description(fields)
    group = Group.new(fields.slice("name", "description"))
    save(group)
    show(group.id)
  end

  def self.update(id, fields)
    check_name(fields["name"], "Group name is required") if fields.key?("name")
    check_description(fields)
    group = find(Group, id)
    group.assign_attributes(fields.slice("name", "description"))
    save(group)
    show(id)
  end

  def self.delete(id)
    find(Group, id).destroy!
  end

  def self.groups
    Group.includes(character_groups: :character)
  end
  private_class_method :groups

  def self.check_description(fields)
    description = fields["description"]
    reject("Description must be a string or null") unless description.nil? || description.is_a?(String)
  end
  private_class_method :check_description
end
