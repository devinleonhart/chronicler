module EventsHelper
  # Such as "20", "20 → 23" across a span, or "42 (deceased)".
  def event_ages(event, character)
    dates = [event.start_date]
    dates << event.end_date if event.end_date && event.end_date != event.start_date
    dates.map { |date| age_text(character, date) }.join(" → ")
  end

  def timeline_items(events)
    events.map do |event|
      { id: event.id, name: event.name, start: event.start_date, end: event.end_date,
        currentDay: event.is_current_day, url: edit_event_path(event) }
    end
  end

  private

  def age_text(character, date)
    age = AgeCalculator.on(character.birth_date, date, character.death_date)
    age.deceased ? "#{age.years} (deceased)" : age.years.to_s
  end
end
