# Rails loads db/schema.rb into a database without its bookkeeping tables. On the
# Nuxt application's database that would add empty tables beside the old ones and
# skip the conversion, so such a database gets the bookkeeping tables first.
namespace :db do
  desc "Mark a Nuxt database as initialized, so that it is converted"
  task recognize_legacy: :load_config do
    tasks = ActiveRecord::Tasks::DatabaseTasks
    tasks.with_temporary_pool_for_each(env: tasks.env) do |pool|
      legacy = %w[UniverseSettings Group Character CharacterGroup Event EventCharacter]
      next unless legacy.any? { |table| pool.lease_connection.table_exists?(table) }

      pool.schema_migration.create_table
      pool.internal_metadata.create_table
    rescue ActiveRecord::NoDatabaseError
      next
    end
  end
end

%w[db:migrate db:prepare].each { |task| Rake::Task[task].enhance(["db:recognize_legacy"]) }
