# Only a changed date is checked, so that narrowing the universe does not freeze records outside it.
class UniverseBoundsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless record.will_save_change_to_attribute?(attribute) && CalendarDate.valid?(value)

    universe = UniverseSetting.current or return
    if value < universe.start_date
      record.errors.add(attribute, :before_universe, limit: universe.start_date)
    elsif value > universe.end_date
      record.errors.add(attribute, :after_universe, limit: universe.end_date)
    end
  end
end
