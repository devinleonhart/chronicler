class EventsController < ApplicationController
  include DialogForms

  opens_in_dialog :new, :edit
  before_action :set_event, only: [:edit, :update, :destroy]

  def index
    @universe = UniverseSetting.current!
    @groups = Group.by_name
    @listing = EventListing.new(
      query: text_param(:q), group_ids: list_param(:group_ids), births: text_param(:births) == "1",
      sort: text_param(:sort), direction: text_param(:dir), view: text_param(:view)
    )
  end

  def new
    @event = Event.new
  end

  def edit; end

  def create
    @event = Event.new(event_params)
    return render(:new, status: :unprocessable_content) unless @event.save

    respond_saved "Event added successfully"
  end

  def update
    return render(:edit, status: :unprocessable_content) unless @event.update(event_params)

    respond_saved "Event updated successfully"
  end

  def destroy
    return respond_deleted("Event deleted") if @event.destroy

    redirect_to events_path, status: :see_other, flash: { error: @event.errors.full_messages.first }
  end

  private

  def set_event
    @event = Event.find(params.expect(:id))
  end

  def event_params
    without_blank_ids(params.expect(event: [:name, :start_date, :end_date, { character_ids: [] }]), :character_ids)
  end
end
