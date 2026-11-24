# Updates several characters, or none.
module BulkCharacterOperation
  extend OperationChecks

  class << self
    def update(fields)
      updates = fields["updates"]
      reject("updates must be a non-empty array") if !updates.is_a?(Array) || updates.empty?

      check_updates(updates)
      ids = updates.map { |update| update["id"].to_i }
      check_found(ids)
      Character.transaction { updates.each { |update| apply(update) } }
      CharacterOperations.list_of(ids)
    end

    private

    # Types are checked in every update before dates are checked in any.
    def check_updates(updates)
      updates.each { |update| check_update(update) }
      updates.map { |update| check_update_dates(update) }
    end

    def check_update(update)
      id = fields_of(update)["id"]
      unless positive_integer?(id)
        shown = fields_of(update).key?("id") ? JSON.generate(id) : "undefined"
        reject("Each update must have a positive integer id (got: #{shown})")
      end

      check_name(update["name"], "#{label(update)}: name must be a non-empty string") if update.key?("name")
      check_date(update["birthDate"], messages(update)[:birth_date]) if update.key?("birthDate")
      check_date(update["deathDate"], messages(update)[:death_date]) unless update["deathDate"].nil?
      check_list(update["groupIds"], "#{label(update)}: groupIds must be an array") if update.key?("groupIds")
    end

    # Null fails like any unexpected error; other values that are not objects have no fields.
    def fields_of(update)
      raise TypeError, "An update is null" if update.nil?

      update.is_a?(Hash) ? update : {}
    end

    def check_update_dates(update)
      dates = { birth_date: "birthDate", death_date: "deathDate" }.filter_map do |attribute, field|
        next unless update[field]

        [attribute, OperationChecks::SentDate.new(update[field], messages(update)[attribute])]
      end.to_h
      check_dates(Character, dates,
                  birth_date: "#{label(update)} birthDate", death_date: "#{label(update)} deathDate")
    end

    def check_found(ids)
      ids.each { |id| in_range(id) }
      missing = ids - Character.where(id: ids).ids
      reject("Characters not found: #{missing.join(', ')}", :not_found) if missing.any?
    end

    def apply(update)
      character = Character.find(update["id"].to_i)
      character.assign_attributes(attributes(update, CharacterOperations::FIELDS))
      save(character, "#{label(update)}: ")
    end

    def label(update)
      "Character #{update['id'].to_i}"
    end

    def messages(update)
      { birth_date: "#{label(update)}: birthDate must be YYYY-MM-DD",
        death_date: "#{label(update)}: deathDate must be YYYY-MM-DD or null" }
    end
  end
end
