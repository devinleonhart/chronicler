module Api
  class BulkCharactersController < CharactersController
    def update
      updates = body["updates"]
      reject("updates must be a non-empty array") if !updates.is_a?(Array) || updates.empty?

      check_updates(updates)
      ids = updates.map { |fields| fields["id"].to_i }
      check_found(ids)
      Character.transaction { updates.each { |fields| apply(fields) } }
      render_characters characters.where(id: ids)
    end

    private

    # Types are checked in every update before dates are checked in any.
    def check_updates(updates)
      updates.each { |fields| check_update(fields) }
      updates.map { |fields| check_update_dates(fields) }
    end

    def check_update(fields)
      id = fields_of(fields)["id"]
      unless positive_integer?(id)
        shown = fields_of(fields).key?("id") ? JSON.generate(id) : "undefined"
        reject("Each update must have a positive integer id (got: #{shown})")
      end

      check_name(fields["name"], "#{label(fields)}: name must be a non-empty string") if fields.key?("name")
      check_date(fields["birthDate"], messages(fields)[:birth_date]) if fields.key?("birthDate")
      check_date(fields["deathDate"], messages(fields)[:death_date]) unless fields["deathDate"].nil?
      check_list(fields["groupIds"], "#{label(fields)}: groupIds must be an array") if fields.key?("groupIds")
    end

    # Null fails like any unexpected error; other values that are not objects have no fields.
    def fields_of(fields)
      raise TypeError, "An update is null" if fields.nil?

      fields.is_a?(Hash) ? fields : {}
    end

    def check_update_dates(fields)
      dates = sent_dates(fields, messages(fields)[:birth_date])
      dates[:death_date] = dates[:death_date].with(message: messages(fields)[:death_date]) if dates[:death_date]
      check_dates(Character, dates,
                  birth_date: "#{label(fields)} birthDate", death_date: "#{label(fields)} deathDate")
    end

    def check_found(ids)
      raise RangeError, "An id is out of range" if ids.any? { |id| id > StagedMembers::MAX_ID }

      missing = ids - Character.where(id: ids).ids
      reject("Characters not found: #{missing.join(', ')}", :not_found) if missing.any?
    end

    def apply(fields)
      character = Character.find(fields["id"].to_i)
      character.assign_attributes(attributes(fields))
      save(character, "#{label(fields)}: ")
    end

    def label(fields)
      "Character #{fields['id'].to_i}"
    end

    def messages(fields)
      { birth_date: "#{label(fields)}: birthDate must be YYYY-MM-DD",
        death_date: "#{label(fields)}: deathDate must be YYYY-MM-DD or null" }
    end
  end
end
