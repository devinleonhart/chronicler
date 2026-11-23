# The sample Knighthood universe, for development only: preparing a test or
# production database also runs this file.
if Rails.env.development? && !UniverseSetting.exists?
  ActiveRecord::Base.transaction do
    JSON.parse(Rails.root.join("db/seeds/knighthood.json").read).each do |table, rows|
      model = table.classify.constantize
      times = model.column_names.include?("updated_at") ? { updated_at: Time.current } : {}
      model.insert_all!(rows.map { |row| row.merge(times) }) # rubocop:disable Rails/SkipsModelValidations
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end
  end
end
