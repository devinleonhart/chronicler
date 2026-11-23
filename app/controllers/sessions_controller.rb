class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: :refuse_attempt

  def new; end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password).with_defaults(email_address: "", password: ""))
    return redirect_to(new_session_path, alert: "Try another email address or password.") if user.nil?

    destination = after_authentication_url
    start_new_session_for(user)
    redirect_to destination
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def refuse_attempt
    redirect_to new_session_path, alert: "Try again later."
  end
end
