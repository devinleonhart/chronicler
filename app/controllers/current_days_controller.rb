class CurrentDaysController < ApplicationController
  def show
    @day = UniverseSetting.current!.current_day
    @by_group = text_param(:view) == "group"
    @roster = Roster.new(@day)
  end
end
