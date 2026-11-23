# frozen_string_literal: true

# Records the HTTP API's responses, and compares later implementations to them.
#
#   ruby contract/replay.rb record <url>     write golden.json
#   ruby contract/replay.rb verify <url>     compare with golden.json; exit 1 on differences
#   ruby contract/replay.rb coverage         list the routes that requests.json exercises
#
#   --only settings,groups    run only these sections
#   --header "Name: value"    add a header to every request; repeatable
#
# The database must be freshly loaded from seed.sql. Each section restores what
# it changes and creates rows in its own table only, so ids do not depend on
# which sections ran before. A section marked "database": "empty" needs a
# migrated database with no rows, and runs only when named by --only.

require "json"
require "net/http"
require "optparse"
require "uri"

module Contract
  DIR = __dir__
  REQUESTS = File.join(DIR, "requests.json")
  GOLDEN = File.join(DIR, "golden.json")

  ROUTES = [
    "GET /api/settings",
    "PUT /api/settings",
    "GET /api/groups",
    "POST /api/groups",
    "GET /api/groups/:id",
    "PUT /api/groups/:id",
    "DELETE /api/groups/:id",
    "GET /api/characters",
    "POST /api/characters",
    "PUT /api/characters/bulk",
    "GET /api/characters/placeholders",
    "GET /api/characters/:id",
    "PUT /api/characters/:id",
    "DELETE /api/characters/:id",
    "GET /api/characters/:id/events",
    "POST /api/characters/:id/groups",
    "DELETE /api/characters/:id/groups/:groupId",
    "GET /api/events",
    "POST /api/events",
    "GET /api/events/:id",
    "PUT /api/events/:id",
    "DELETE /api/events/:id",
    "POST /api/events/:id/characters",
    "DELETE /api/events/:id/characters/:characterId",
    "GET /api/summary"
  ].freeze

  # Top-level records separate date and time with a space, nested ones with T.
  TIMESTAMP = /\A\d{4}-\d{2}-\d{2}([ T])\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?\z/
  MEMBERSHIPS = { "characterGroups" => %w[characterId groupId], "eventCharacters" => %w[eventId characterId] }.freeze

  module_function

  def normalize(value)
    case value
    when Hash then value.to_h { |key, item| [key, normalize_field(key, item)] }
    when Array then sort_tied_events(value.map { |item| normalize(item) })
    else value
    end
  end

  def normalize_field(key, value)
    if %w[createdAt updatedAt].include?(key)
      match = TIMESTAMP.match(value.to_s)
      return match ? "<timestamp YYYY-MM-DD#{match[1]}HH:MM:SS>" : value
    end

    result = normalize(value)
    return result unless MEMBERSHIPS.key?(key) && result.is_a?(Array)

    result.sort_by { |row| MEMBERSHIPS.fetch(key).map { |id| row[id].to_i } }
  end

  # Only runs of equal startDate are reordered, so a wrong date order still shows.
  def sort_tied_events(list)
    return list unless list.any? && list.all? do |item|
      item.is_a?(Hash) && item.key?("startDate") && item.key?("isCurrentDay")
    end

    list.chunk_while { |a, b| a["startDate"] == b["startDate"] }.flat_map { |run| run.sort_by { |event| event["id"] } }
  end

  def normalize_body(content_type, body)
    if content_type.to_s.start_with?("application/json") && !body.empty?
      normalize(JSON.parse(body))
    else
      body.gsub(/^Generated: \d{4}-\d{2}-\d{2}$/, "Generated: <date>")
    end
  rescue JSON::ParserError
    body
  end

  def perform(base, request, headers)
    uri = URI.join(base, request.fetch("path"))
    http_request = Net::HTTP.const_get(request.fetch("method").capitalize).new(uri)
    headers.merge(request.fetch("headers", {})).each { |name, value| http_request[name] = value }
    if request.key?("raw") || request.key?("body")
      http_request["Content-Type"] ||= "application/json"
      http_request.body = request.fetch("raw") { JSON.generate(request["body"]) }
    end

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(http_request) }
    body = response.body.to_s.dup.force_encoding(Encoding::UTF_8)
    { "status" => response.code.to_i, "contentType" => response["content-type"],
      "body" => normalize_body(response["content-type"], body) }
  end

  def differences(expected, actual, at = "")
    if expected.is_a?(Hash) && actual.is_a?(Hash)
      (expected.keys | actual.keys).flat_map do |key|
        next ["#{at}.#{key}: missing"] unless actual.key?(key)
        next ["#{at}.#{key}: unexpected"] unless expected.key?(key)

        differences(expected[key], actual[key], "#{at}.#{key}")
      end
    elsif expected.is_a?(Array) && actual.is_a?(Array) && expected.size == actual.size
      expected.each_index.flat_map { |i| differences(expected[i], actual[i], "#{at}[#{i}]") }
    elsif expected.eql?(actual)
      []
    else
      ["#{at}: expected #{expected.inspect}, got #{actual.inspect}"]
    end
  end

  def load_sections(only)
    sections = JSON.parse(File.read(REQUESTS)).fetch("sections")
    names = sections.map { |section| section["name"] }
    labels = sections.flat_map { |s| s["requests"].map { |r| "#{s['name']}: #{r['name']}" } }
    duplicates = labels.tally.select { |_, n| n > 1 }
    abort "Duplicate requests: #{duplicates.keys.join('; ')}" if duplicates.any?
    unknown = only.to_a - names
    abort "Unknown sections: #{unknown.join(', ')}. Known: #{names.join(', ')}" if unknown.any?

    chosen = only ? sections.select { |s| only.include?(s["name"]) } : sections.reject { |s| s["database"] == "empty" }
    abort "No sections selected" if chosen.empty?
    if chosen.map { |s| s["database"] }.uniq.size > 1
      abort "Sections for an empty and a seeded database cannot run together"
    end
    chosen
  end

  def run(sections, base, headers)
    sections.to_h do |section|
      [section["name"], section["requests"].to_h { |request| [request["name"], perform(base, request, headers)] }]
    end
  end

  def record(sections, base, headers)
    golden = File.exist?(GOLDEN) ? JSON.parse(File.read(GOLDEN)) : {}
    golden.merge!(run(sections, base, headers))
    order = JSON.parse(File.read(REQUESTS)).fetch("sections").map { |s| s["name"] }
    golden = golden.slice(*order)
    File.write(GOLDEN, "#{JSON.pretty_generate(golden)}\n")
    puts "#{golden.slice(*sections.map { |s| s['name'] }).sum { |_, r| r.size }} responses recorded"
    true
  end

  def verify(sections, base, headers)
    golden = JSON.parse(File.read(GOLDEN))
    actual = run(sections, base, headers)
    count = 0
    differing = 0
    sections.each do |section|
      expected = golden.fetch(section["name"], {})
      names = actual[section["name"]].keys | expected.keys
      names.each do |name|
        count += 1
        found = if !expected.key?(name) then [": not recorded in golden.json"]
                elsif !actual[section["name"]].key?(name) then [": recorded but absent from requests.json"]
                else differences(expected[name], actual[section["name"]][name])
                end
        next if found.empty?

        differing += 1
        puts "#{section['name']}: #{name}"
        found.first(10).each { |line| puts "  #{line}" }
        puts "  ... #{found.size - 10} more" if found.size > 10
      end
    end
    puts "#{count} responses compared, #{differing} differences"
    differing.zero?
  end

  def coverage
    sections = JSON.parse(File.read(REQUESTS)).fetch("sections")
    # Literal routes such as /characters/bulk take precedence over /characters/:id.
    patterns = ROUTES.sort_by { |route| route.count(":") }.to_h do |route|
      [route, /\A#{route.gsub(/:\w+/, '[^/]+')}\z/]
    end
    requests = sections.flat_map { |section| section["requests"] }
    hits = requests.map { |r| "#{r['method']} #{r['path'].split('?').first}" }
                   .map { |line| patterns.find { |_, pattern| pattern.match?(line) }&.first }.tally
    ROUTES.each { |route| puts "#{hits.fetch(route, 0).to_s.rjust(4)}  #{route}" }
    covered = ROUTES.count { |route| hits.key?(route) }
    puts "#{covered} of #{ROUTES.size} patterns covered"
    covered == ROUTES.size
  end

  def main(argv)
    only = nil
    headers = {}
    parser = OptionParser.new do |options|
      options.banner = "Usage: replay.rb record|verify URL [options], or replay.rb coverage"
      options.on("--only SECTIONS", Array, "comma-separated section names") { |names| only = names }
      options.on("--header HEADER", "\"Name: value\", repeatable") do |header|
        name, value = header.split(":", 2)
        raise OptionParser::InvalidArgument, header unless value

        headers[name.strip] = value.strip
      end
    end
    command, base = parser.parse(argv)
    return coverage if command == "coverage"

    abort parser.help unless %w[record verify].include?(command) && base
    public_send(command, load_sections(only), base, headers)
  end
end

exit(Contract.main(ARGV) ? 0 : 1) if $PROGRAM_NAME == __FILE__
