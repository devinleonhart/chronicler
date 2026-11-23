require "fileutils"
require "open3"
require "pg"
require "tmpdir"
require "uri"

# A throwaway database next to the test database, for specs that migrate up and down.
class SeparateDatabase
  BOOKKEEPING = %w[schema_migrations ar_internal_metadata].freeze

  def initialize(name)
    @name = name
    @test_url = ActiveRecord::Base.configurations.find_db_config("test").url ||
                ENV.fetch("TEST_DATABASE_URL")
  end

  def recreate
    drop
    admin { |connection| connection.exec("CREATE DATABASE #{@name}") }
  end

  def drop
    admin { |connection| connection.exec("DROP DATABASE IF EXISTS #{@name} WITH (FORCE)") }
  end

  def load(path)
    capture("psql", "--quiet", "--set", "ON_ERROR_STOP=1", "--dbname", url, "--file", path.to_s)
  end

  # Rails loads the schema file into a database it has not seen before, so
  # whether there is one decides if an empty database runs the migrations.
  def migrate_to(version, schema_file: true)
    rails("db:migrate", version, schema_file:)
  end

  def migrate_down(version)
    rails("db:migrate:down", version)
  end

  def prepare
    rails("db:prepare", nil)
  end

  def dump(*options)
    excluded = BOOKKEEPING.map { |table| "--exclude-table=public.#{table}" }
    # pg_dump wraps its output in \restrict lines with a random key.
    capture("pg_dump", "--dbname", url, *excluded, *options).lines.grep_v(/^\\(un)?restrict /).join
  end

  def rows(table)
    query("SELECT * FROM #{PG::Connection.quote_ident(table)}").values.sort_by(&:inspect)
  end

  def columns(table)
    query("SELECT * FROM #{PG::Connection.quote_ident(table)} LIMIT 0").fields
  end

  def query(sql)
    connection = PG.connect(url)
    connection.exec(sql)
  ensure
    connection&.close
  end

  private

  def url
    URI.parse(@test_url).tap { |uri| uri.path = "/#{@name}" }.to_s
  end

  def admin
    connection = PG.connect(@test_url)
    connection.set_notice_processor { |_| nil }
    yield connection
  ensure
    connection&.close
  end

  # SCHEMA points to a copy, because the tasks rewrite it.
  def rails(task, version, schema_file: true)
    Dir.mktmpdir do |directory|
      schema = File.join(directory, "schema.rb")
      FileUtils.cp(Rails.root.join("db/schema.rb"), schema) if schema_file
      env = { "RAILS_ENV" => "test", "TEST_DATABASE_URL" => url, "SCHEMA" => schema, "VERSION" => version }
      capture(env, Rails.root.join("bin/rails").to_s, task)
    end
  end

  def capture(*command)
    output, error, status = Open3.capture3(*command)
    raise "#{command.grep(String).first(2).join(' ')} failed: #{error}#{output}" unless status.success?

    output
  end
end
