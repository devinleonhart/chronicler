# Ages in whole years, from YYYY-MM-DD strings.
module AgeCalculator
  Age = Data.define(:years, :deceased)

  module_function

  def years(birth_date, date)
    years = date[0, 4].to_i - birth_date[0, 4].to_i
    years -= 1 if date[5..] < birth_date[5..]
    [years, 0].max
  end

  # Such as "29", or "29–32" when a birthday falls within the dates.
  def range(birth_date, start_date, end_date)
    ages = [start_date, end_date].compact.map { |date| years(birth_date, date) }
    ages.uniq.join("–")
  end

  # The age on a date, or at death if that came before.
  def on(birth_date, date, death_date = nil)
    deceased = death_date.present? && date > death_date
    Age.new(years: years(birth_date, deceased ? death_date : date), deceased:)
  end
end
