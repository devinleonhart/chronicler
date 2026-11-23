# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_23_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "character_groups", primary_key: ["character_id", "group_id"], force: :cascade do |t|
    t.integer "character_id", null: false
    t.integer "group_id", null: false
    t.index ["group_id"], name: "index_character_groups_on_group_id"
  end

  create_table "characters", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.string "name", limit: 255, null: false
    t.string "birth_date", limit: 10, null: false
    t.string "death_date", limit: 10
    t.check_constraint "birth_date::text ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'::text", name: "characters_birth_date_format"
    t.check_constraint "death_date::text ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'::text", name: "characters_death_date_format"
  end

  create_table "event_characters", primary_key: ["event_id", "character_id"], force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "character_id", null: false
    t.index ["character_id"], name: "index_event_characters_on_character_id"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.string "name", limit: 255, null: false
    t.string "start_date", limit: 10, null: false
    t.string "end_date", limit: 10
    t.boolean "is_current_day", default: false, null: false
    t.check_constraint "end_date::text ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'::text", name: "events_end_date_format"
    t.check_constraint "start_date::text ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'::text", name: "events_start_date_format"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.string "name", limit: 255, null: false
    t.text "description"
  end

  create_table "universe_settings", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, null: false
    t.string "name", limit: 255, default: "My Universe", null: false
    t.string "start_date", limit: 10, null: false
    t.string "end_date", limit: 10, null: false
    t.string "current_day", limit: 10, null: false
    t.check_constraint "current_day::text ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'::text", name: "universe_settings_current_day_format"
    t.check_constraint "end_date::text ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'::text", name: "universe_settings_end_date_format"
    t.check_constraint "start_date::text ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'::text", name: "universe_settings_start_date_format"
  end

  add_foreign_key "character_groups", "characters", name: "character_groups_character_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "character_groups", "groups", name: "character_groups_group_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "event_characters", "characters", name: "event_characters_character_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "event_characters", "events", name: "event_characters_event_id_fkey", on_update: :cascade, on_delete: :cascade
end
