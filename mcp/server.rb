#!/usr/bin/env ruby
# frozen_string_literal: true

# An MCP server over stdio for Chronicler's API.
#
#   CHRONICLER_URL       where Chronicler runs (default http://localhost:3000)
#   CHRONICLER_API_KEY   its API key
#
# Only protocol messages may reach stdout.

ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", __dir__)
require "bundler/setup"
require "json"
require "mcp"
require "net/http"
require "uri"

module Chronicler
  # Requests to the API.
  module Api
    Answer = Data.define(:status, :data) do
      def success? = status.between?(200, 299)
    end

    URL = ENV.fetch("CHRONICLER_URL", "http://localhost:3000")
    KEY = ENV.fetch("CHRONICLER_API_KEY", "")

    def self.call(method, path, query: {}, body: nil)
      uri = URI("#{URL}#{path}")
      uri.query = URI.encode_www_form(query) unless query.empty?
      request = Net::HTTP.const_get(method.capitalize).new(uri)
      request["Authorization"] = "Bearer #{KEY}" unless KEY.empty?
      if body
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
      end
      read(Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) })
    end

    def self.read(response)
      text = response.body.to_s.dup.force_encoding(Encoding::UTF_8)
      json = response["content-type"].to_s.include?("application/json") && !text.empty?
      Answer.new(status: response.code.to_i, data: json ? JSON.parse(text) : text)
    end
  end

  # JSON schemas of the tools' inputs.
  module Schema
    DATE_PATTERN = '^\d{4}-\d{2}-\d{2}$'

    module_function

    def id(description) = { type: "integer", exclusiveMinimum: 0, description: }
    def text(description) = { type: "string", description: }
    def name(description) = { type: "string", minLength: 1, description: }
    def nullable_text(description) = { type: %w[string null], description: }
    def date(description) = { type: "string", pattern: DATE_PATTERN, description: }

    def nullable_date(description)
      { anyOf: [{ type: "string", pattern: DATE_PATTERN }, { type: "null" }], description: }
    end

    def ids(description, **)
      { type: "array", items: { type: "integer", exclusiveMinimum: 0 }, description:, ** }
    end

    def object(properties, required = [])
      schema = { type: "object", properties: }
      required.empty? ? schema : schema.merge(required:)
    end
  end

  # The tools, each a class of the MCP library.
  module Tools # rubocop:disable Metrics/ModuleLength
    S = Schema

    LIST = [] # rubocop:disable Style/MutableConstant

    module_function

    # Defines a tool. The block gets its known arguments and gives the text of the result.
    def tool(name, description, properties = {}, required: [], &block)
      known = properties.keys
      LIST << MCP::Tool.define(name:, description:, input_schema: S.object(properties, required)) do |**arguments|
        Tools.respond { block.call(arguments.slice(*known)) }
      end
    end

    def respond
      MCP::Tool::Response.new([{ type: "text", text: yield }])
    rescue StandardError => error
      MCP::Tool::Response.new([{ type: "text", text: "#{error.class}: #{error.message}" }], error: true)
    end

    def get(path, query = {})
      JSON.pretty_generate(Api.call("GET", path, query: query.compact).data)
    end

    def send_body(method, path, body)
      JSON.pretty_generate(Api.call(method, path, body:).data)
    end

    def delete(path)
      JSON.pretty_generate(Api.call("DELETE", path).data)
    end

    # Deletions of records answer without a body.
    def remove(path)
      answer = Api.call("DELETE", path)
      JSON.pretty_generate({ success: answer.success?, status: answer.status })
    end

    def summary(ids)
      data = Api.call("GET", "/api/summary", query: { characterIds: ids.join(",") }).data
      data.is_a?(String) ? data : JSON.pretty_generate(data)
    end

    # ── Characters ──────────────────────────────────────────────────────────────

    tool("list_characters", "List all characters with their group memberships", {
           name: S.text("Filter by name (case-insensitive partial match)"),
           groupId: S.id("Filter to characters belonging to this group ID"),
           birthYear: S.id("Filter to characters born in this year")
         }) { |filters| get("/api/characters", filters) }

    tool("find_placeholder_characters", "Find characters with a placeholder birth date (default: 2200-01-01)", {
           birthDate: S.date("Placeholder birth date to match (YYYY-MM-DD); defaults to 2200-01-01")
         }) { |filters| get("/api/characters/placeholders", filters) }

    tool("get_character", "Get a single character by ID", { id: S.id("Character ID") }, required: ["id"]) do |input|
      get("/api/characters/#{input[:id]}")
    end

    tool("get_character_events", "Get all events for a character, ordered chronologically",
         { id: S.id("Character ID") }, required: ["id"]) do |input|
      get("/api/characters/#{input[:id]}/events")
    end

    tool("create_character", "Create a new character", {
           name: S.name("Character name"),
           birthDate: S.date("Birth date (YYYY-MM-DD)"),
           deathDate: S.date("Death date (YYYY-MM-DD), omit if alive"),
           groupIds: S.ids("Group IDs to assign this character to")
         }, required: %w[name birthDate]) { |fields| send_body("POST", "/api/characters", fields) }

    tool("update_character", "Update an existing character", {
           id: S.id("Character ID"),
           name: S.name("New name"),
           birthDate: S.date("New birth date (YYYY-MM-DD)"),
           deathDate: S.nullable_date("New death date (YYYY-MM-DD), or null to clear"),
           groupIds: S.ids("Full replacement list of group IDs (replaces existing)")
         }, required: ["id"]) { |fields| send_body("PUT", "/api/characters/#{fields.delete(:id)}", fields) }

    tool("bulk_update_characters", "Update multiple characters in a single transaction", {
           updates: {
             type: "array", minItems: 1, description: "List of character updates to apply",
             items: S.object({
                               id: S.id("Character ID"),
                               name: S.name("New name"),
                               birthDate: S.date("New birth date (YYYY-MM-DD)"),
                               deathDate: S.nullable_date("New death date (YYYY-MM-DD), or null to clear"),
                               groupIds: S.ids("Full replacement list of group IDs")
                             }, ["id"])
           }
         }, required: ["updates"]) { |fields| send_body("PUT", "/api/characters/bulk", fields) }

    tool("delete_character", "Delete a character by ID", { id: S.id("Character ID") }, required: ["id"]) do |input|
      remove("/api/characters/#{input[:id]}")
    end

    # ── Groups ──────────────────────────────────────────────────────────────────

    tool("list_groups", "List all groups with their members") { get("/api/groups") }

    tool("get_group", "Get a single group by ID", { id: S.id("Group ID") }, required: ["id"]) do |input|
      get("/api/groups/#{input[:id]}")
    end

    tool("create_group", "Create a new group", {
           name: S.name("Group name"),
           description: S.nullable_text("Optional description")
         }, required: ["name"]) { |fields| send_body("POST", "/api/groups", fields) }

    tool("update_group", "Update an existing group", {
           id: S.id("Group ID"),
           name: S.name("New name"),
           description: S.nullable_text("New description, or null to clear")
         }, required: ["id"]) { |fields| send_body("PUT", "/api/groups/#{fields.delete(:id)}", fields) }

    tool("delete_group", "Delete a group by ID (does not delete its members)",
         { id: S.id("Group ID") }, required: ["id"]) do |input|
      remove("/api/groups/#{input[:id]}")
    end

    # ── Events ──────────────────────────────────────────────────────────────────

    tool("list_events", "List all events with their characters", {
           name: S.text("Filter by name (case-insensitive partial match)"),
           characterId: S.id("Filter to events featuring this character ID"),
           startAfter: S.date("Filter to events starting on or after this date (YYYY-MM-DD)"),
           startBefore: S.date("Filter to events starting on or before this date (YYYY-MM-DD)")
         }) { |filters| get("/api/events", filters) }

    tool("get_event", "Get a single event by ID", { id: S.id("Event ID") }, required: ["id"]) do |input|
      get("/api/events/#{input[:id]}")
    end

    tool("create_event", "Create a new event", {
           name: S.name("Event name"),
           startDate: S.date("Start date (YYYY-MM-DD)"),
           endDate: S.nullable_date("End date (YYYY-MM-DD), omit for single-day events"),
           characterIds: S.ids("Character IDs to attach to this event")
         }, required: %w[name startDate]) { |fields| send_body("POST", "/api/events", fields) }

    tool("update_event", "Update an existing event", {
           id: S.id("Event ID"),
           name: S.name("New name"),
           startDate: S.date("New start date (YYYY-MM-DD)"),
           endDate: S.nullable_date("New end date (YYYY-MM-DD), or null to clear"),
           characterIds: S.ids("Full replacement list of character IDs (replaces existing)")
         }, required: ["id"]) { |fields| send_body("PUT", "/api/events/#{fields.delete(:id)}", fields) }

    tool("add_character_to_event", "Add a single character to an existing event", {
           eventId: S.id("Event ID"),
           characterId: S.id("Character ID to add")
         }, required: %w[eventId characterId]) do |input|
      send_body("POST", "/api/events/#{input[:eventId]}/characters", input.slice(:characterId))
    end

    tool("remove_character_from_event", "Remove a single character from an existing event", {
           eventId: S.id("Event ID"),
           characterId: S.id("Character ID to remove")
         }, required: %w[eventId characterId]) do |input|
      delete("/api/events/#{input[:eventId]}/characters/#{input[:characterId]}")
    end

    tool("add_group_to_character", "Add a single group membership to a character", {
           characterId: S.id("Character ID"),
           groupId: S.id("Group ID to add")
         }, required: %w[characterId groupId]) do |input|
      send_body("POST", "/api/characters/#{input[:characterId]}/groups", input.slice(:groupId))
    end

    tool("remove_group_from_character", "Remove a single group membership from a character", {
           characterId: S.id("Character ID"),
           groupId: S.id("Group ID to remove")
         }, required: %w[characterId groupId]) do |input|
      delete("/api/characters/#{input[:characterId]}/groups/#{input[:groupId]}")
    end

    tool("delete_event", "Delete an event by ID (cannot delete the Current Day event)",
         { id: S.id("Event ID") }, required: ["id"]) do |input|
      remove("/api/events/#{input[:id]}")
    end

    # ── Settings ────────────────────────────────────────────────────────────────

    tool("get_settings", "Get universe settings (name, date bounds, current day)") { get("/api/settings") }

    tool("update_settings", "Update universe settings", {
           name: S.name("Universe name"),
           startDate: S.date("Universe start date (YYYY-MM-DD)"),
           endDate: S.date("Universe end date (YYYY-MM-DD)"),
           currentDay: S.date("Current day reference date (YYYY-MM-DD); also updates the Current Day event")
         }) { |fields| send_body("PUT", "/api/settings", fields) }

    # ── Summary ─────────────────────────────────────────────────────────────────

    tool("get_summary", "Generate a plain-text narrative summary of events for one or more characters", {
           characterIds: S.ids("Character IDs to include in the summary", minItems: 1)
         }, required: ["characterIds"]) { |input| summary(input[:characterIds]) }
  end
end

server = MCP::Server.new(name: "chronicler", version: "1.0.0", tools: Chronicler::Tools::LIST)
MCP::Server::Transports::StdioTransport.new(server).open
