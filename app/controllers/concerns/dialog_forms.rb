# Forms for new and existing records open in the layout's dialog.
module DialogForms
  extend ActiveSupport::Concern

  class_methods do
    def opens_in_dialog(*actions)
      before_action(:require_dialog, only: actions)
    end
  end

  private

  def require_dialog
    redirect_to({ action: :index }, status: :see_other) unless turbo_frame_request?
  end

  # Reloads the page under the dialog, which keeps its address and filters.
  def respond_saved(message)
    flash[:success] = message
    return redirect_to({ action: :index }, status: :see_other) unless turbo_frame_request?

    render turbo_stream: turbo_stream.refresh(request_id: nil)
  end

  # Forms send a blank id, so that clearing every choice sends something.
  def without_blank_ids(fields, name)
    fields[name] = fields[name].compact_blank if fields[name]
    fields
  end

  def respond_deleted(message)
    redirect_back_or_to({ action: :index }, status: :see_other, flash: { success: message })
  end
end
