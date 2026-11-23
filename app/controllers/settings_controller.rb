class SettingsController < ApplicationController
  before_action :set_setting

  def show; end

  def update
    @setting.assign_attributes(params.expect(universe_setting: [:name, :start_date, :end_date, :current_day]))
    return render(:show, status: :unprocessable_content) unless @setting.save(context: :form)

    redirect_to settings_path, status: :see_other, flash: { success: "Settings saved" }
  end

  private

  def set_setting
    @setting = UniverseSetting.current!
  end
end
