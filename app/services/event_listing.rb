# The events page's rows: events and, if asked for, births and deaths.
class EventListing
  Life = Data.define(:kind, :name, :start_date) do
    def end_date = nil
  end

  DEFAULTS = { sort: "start_date", dir: "asc", view: "list" }.freeze
  SORTS = %w[name start_date end_date].freeze

  attr_reader :query, :group_ids, :births, :sort, :direction, :view

  # rubocop:disable-next Metrics/ParameterLists
  def initialize(query: "", group_ids: [], births: false, sort: nil, direction: nil, view: nil)
    @query = query
    @group_ids = group_ids.filter_map { |id| StagedMembers.parse_id(id) }
    @births = births
    @sort = SORTS.include?(sort) ? sort : "start_date"
    @direction = direction == "desc" ? "desc" : "asc"
    @view = view == "timeline" ? "timeline" : "list"
  end

  def timeline?
    view == "timeline"
  end

  def filtered?
    query.present? || group_ids.any?
  end

  # The page's address, without its defaults.
  def to_params(**changes)
    all = { q: query, group_ids:, births: ("1" if births), sort:, dir: direction, view: }.merge(changes)
    all.reject { |key, value| value.blank? || DEFAULTS[key] == value }
  end

  # A column sorts ascending first, then descending.
  def sort_params(column)
    to_params(sort: column, dir: column == sort && direction == "asc" ? "desc" : "asc")
  end

  def events
    @events ||= Event.matching(query).involving_groups(group_ids).includes(:characters).chronological.to_a
  end

  def rows
    sorted(events + lives)
  end

  private

  def lives
    return [] unless births

    scope = Character.by_name.name_matching(query)
    scope = scope.in_group(group_ids) if group_ids.any?
    scope.flat_map do |character|
      born = Life.new(kind: "birth", name: "#{character.name} born", start_date: character.birth_date)
      next [born] unless character.death_date

      [born, Life.new(kind: "death", name: "#{character.name} died", start_date: character.death_date)]
    end
  end

  # Rows with equal values keep their order in both directions.
  def sorted(list)
    sign = direction == "desc" ? -1 : 1
    list.each_with_index.sort do |(a, i), (b, j)|
      order = (a.public_send(sort).to_s <=> b.public_send(sort).to_s) * sign
      order.zero? ? i <=> j : order
    end.map(&:first)
  end
end
