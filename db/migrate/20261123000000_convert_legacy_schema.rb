# Renames the Nuxt application's tables in place, so no rows are copied. A database
# without them gets them first, and so ends with the same schema.
class ConvertLegacySchema < ActiveRecord::Migration[8.1]
  TABLES = {
    "UniverseSettings" => "universe_settings",
    "Group" => "groups",
    "Character" => "characters",
    "CharacterGroup" => "character_groups",
    "Event" => "events",
    "EventCharacter" => "event_characters"
  }.freeze

  DATES = {
    "universe_settings" => %w[start_date end_date current_day],
    "characters" => %w[birth_date death_date],
    "events" => %w[start_date end_date]
  }.freeze

  SECOND_COLUMNS = {
    "character_groups" => "group_id",
    "event_characters" => "character_id"
  }.freeze

  def up
    prepare_legacy_tables

    TABLES.each do |legacy, table|
      rename_everything(legacy, table, columns_of(legacy).index_with(&:underscore))
    end

    DATES.each do |table, columns|
      columns.each do |column|
        execute <<~SQL.squish
          ALTER TABLE #{q(table)} ADD CONSTRAINT #{q(check_name(table, column))}
          CHECK (#{q(column)} ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
        SQL
      end
    end
    SECOND_COLUMNS.each do |table, column|
      execute "CREATE INDEX #{q(index_name_for(table, column))} ON #{q(table)} (#{q(column)})"
    end
  end

  def down
    SECOND_COLUMNS.each { |table, column| execute "DROP INDEX #{q(index_name_for(table, column))}" }
    DATES.each do |table, columns|
      columns.each { |column| execute "ALTER TABLE #{q(table)} DROP CONSTRAINT #{q(check_name(table, column))}" }
    end

    TABLES.each do |legacy, table|
      rename_everything(table, legacy, columns_of(table).index_with { |column| column.camelize(:lower) })
    end
  end

  private

  def prepare_legacy_tables
    missing = TABLES.keys.reject { |table| table_exists?(table) }
    return if missing.empty?
    raise "Legacy tables are missing: #{missing.join(', ')}" if missing.size < TABLES.size

    execute Rails.root.join("db/legacy_schema.sql").read
  end

  # Constraints are renamed before their columns and table, whose names they contain.
  def rename_everything(from, to, columns)
    constraints_of(from).each do |name|
      rename_to = rename_constraint(name, from, to, columns)
      next if rename_to == name

      execute "ALTER TABLE #{q(from)} RENAME CONSTRAINT #{q(name)} TO #{q(rename_to)}"
    end
    execute "ALTER SEQUENCE #{q("#{from}_id_seq")} RENAME TO #{q("#{to}_id_seq")}" if columns.key?("id")
    columns.each do |old, new|
      execute "ALTER TABLE #{q(from)} RENAME COLUMN #{q(old)} TO #{q(new)}" if old != new
    end
    execute "ALTER TABLE #{q(from)} RENAME TO #{q(to)}"
  end

  # Names are <table>_pkey, <table>_<column>_fkey and <table>_<column>_not_null.
  def rename_constraint(name, from, to, columns)
    suffix = name.delete_prefix("#{from}_")
    return name if suffix == name

    column = columns.keys.find { |old| suffix.start_with?("#{old}_") }
    suffix = suffix.sub(column, columns.fetch(column)) if column
    "#{to}_#{suffix}"
  end

  def constraints_of(table)
    select_values("SELECT conname FROM pg_constraint WHERE conrelid = #{quote(q(table))}::regclass ORDER BY conname")
  end

  def columns_of(table)
    select_values(<<~SQL.squish)
      SELECT attname FROM pg_attribute
      WHERE attrelid = #{quote(q(table))}::regclass AND attnum > 0 AND NOT attisdropped
      ORDER BY attnum
    SQL
  end

  def check_name(table, column)
    "#{table}_#{column}_format"
  end

  def index_name_for(table, column)
    "index_#{table}_on_#{column}"
  end

  def q(name)
    connection.quote_column_name(name)
  end
end
