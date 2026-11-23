module ApplicationHelper
  def field_errors(record, attribute)
    messages = record.errors.full_messages_for(attribute)
    safe_join(messages.map { |message| tag.p(message, class: "bb-error", role: "alert") })
  end

  # A date as text, since a date picker would discard an impossible one.
  def date_field_for(form, attribute, **)
    form.text_field(attribute, placeholder: "YYYY-MM-DD", inputmode: "numeric", maxlength: 10, autocomplete: "off",
                               class: "bb-input", **)
  end

  def universe_hint
    universe = UniverseSetting.current or return
    tag.p("Dates from #{universe.start_date} to #{universe.end_date}.", class: "bb-hint mb-4")
  end

  def view_link(label, path, current:, **)
    link_to label, path, class: class_names("bb-btn-sm", current ? "bb-btn-primary" : "bb-btn-outline"),
                         aria: { current: ("true" if current) }, **
  end

  def delete_button(label, path, title:, message:)
    button_to "Delete", path, method: :delete, class: "bb-action-text cursor-pointer", aria: { label: },
                              form: { data: { turbo_frame: "_top", turbo_confirm: message, confirm_title: title,
                                              confirm_accept: "Delete" } }
  end

  def nav_links
    {
      "Events" => events_path,
      "Current Day" => current_day_path,
      "Characters" => characters_path,
      "Groups" => groups_path,
      "Summary" => summary_path,
      "Settings" => settings_path
    }
  end
end
