module ApiHelpers
  def send_json(method, path, body = nil)
    public_send(method, path, params: body&.to_json, headers: { "Content-Type" => "application/json" })
  end

  def json
    JSON.parse(response.body)
  end

  def have_error(message)
    have_attributes(status: 400, body: JSON.generate("error" => message))
  end

  # Every row of every table, to show that a refused write changed nothing.
  def all_rows
    [UniverseSetting, Group, Character, Event, CharacterGroup, EventCharacter].index_with do |model|
      model.order(model.primary_key).map(&:attributes)
    end
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
