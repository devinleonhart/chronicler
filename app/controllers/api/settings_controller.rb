module Api
  class SettingsController < BaseController
    def show
      render_json SettingOperations.show
    end

    def update
      render_json SettingOperations.update(body)
    end
  end
end
