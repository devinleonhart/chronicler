module RequestAuthentication
  def sign_in(user = create(:user), password: "correct horse")
    post session_path, params: { email_address: user.email_address, password: }
  end

  # Tests run without forgery protection unless they turn it on.
  def with_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end

module SystemAuthentication
  def sign_in(user = create(:user), password: "correct horse")
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: password
    click_on "Sign In"
    expect(page).to have_button("Sign Out")
  end
end

RSpec.configure do |config|
  config.include RequestAuthentication, type: :request
  config.include SystemAuthentication, type: :system
  # Sign-in attempts are counted in the cache.
  config.before { Rails.cache.clear }
end
