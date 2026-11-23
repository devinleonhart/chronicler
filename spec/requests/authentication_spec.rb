require "rails_helper"

RSpec.describe "Authentication" do
  pages = %w[/events /current-day /characters /groups /summary /settings]

  pages.each do |path|
    it "protects #{path}" do
      get path
      expect(response).to redirect_to(new_session_path)

      sign_in
      get path
      expect(response).to have_http_status(:ok)
    end
  end

  it "shows the six links in order, the current one marked" do
    sign_in
    get "/groups"
    links = response.parsed_body.css("#navbar_desktop a")

    expect(links.map { |link| [link.text.strip, link["href"]] }).to eq(
      [["Events", "/events"], ["Current Day", "/current-day"], ["Characters", "/characters"],
       ["Groups", "/groups"], ["Summary", "/summary"], ["Settings", "/settings"]]
    )
    expect(links.select { |link| link["aria-current"] }.map(&:text).map(&:strip)).to eq(["Groups"])
  end

  it "redirects / to /events" do
    get "/"

    expect(response).to redirect_to("/events")
  end

  it "returns to the requested page after signing in" do
    get "/groups"
    sign_in

    expect(response).to redirect_to("/groups")
  end

  it "goes to the events without a requested page" do
    sign_in
    follow_redirect!

    expect(response).to redirect_to("/events")
  end

  it "refuses a wrong password and an unknown address" do
    user = create(:user)
    sign_in(user, password: "wrong")
    expect(response).to redirect_to(new_session_path)
    sign_in(build(:user, email_address: "other@example.com"))
    expect(response).to redirect_to(new_session_path)
    get "/events"
    expect(response).to redirect_to(new_session_path)
    expect(Session.count).to eq(0)
  end

  it "limits sign-in attempts" do
    user = create(:user)
    10.times { sign_in(user, password: "wrong") }
    sign_in(user)

    expect(flash[:alert]).to eq("Try again later.")
    expect(Session.count).to eq(0)
  end

  it "signs out" do
    sign_in
    delete session_path
    expect(Session.count).to eq(0)
    get "/events"
    expect(response).to redirect_to(new_session_path)
  end

  it "refuses a forged cookie" do
    sign_in
    cookies[:session_id] = Session.sole.id.to_s
    get "/events"

    expect(response).to redirect_to(new_session_path)
  end

  it "keeps the cookie from scripts and other sites" do
    sign_in

    expect(response.headers["Set-Cookie"].to_s).to match(/session_id=.*httponly.*samesite=lax/i)
  end

  it "has no registration or password reset" do
    paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }

    expect(paths.grep(/user|regist|sign_?up|password/)).to be_empty
    %w[/users /users/new /registration/new /passwords/new /sign_up].each do |path|
      get path
      expect(response).to have_http_status(:not_found)
    end
  end

  it "does not let a session into the API without the key" do
    allow(Rails.configuration.x).to receive(:api_key).and_return("secret")
    sign_in
    get "/api/groups"

    expect(response).to have_http_status(:unauthorized)
  end

  it "does not let the API key into the pages" do
    allow(Rails.configuration.x).to receive(:api_key).and_return("secret")
    get "/events", headers: { "Authorization" => "Bearer secret" }

    expect(response).to redirect_to(new_session_path)
  end

  it "sets no cookie on API responses" do
    get "/api/groups"

    expect(response.headers["Set-Cookie"]).to be_nil
  end

  it "sends the content security policy" do
    get new_session_path
    policy = response.headers["Content-Security-Policy"]

    expect(policy).to include("default-src 'self'", "object-src 'none'", "frame-ancestors 'self'")
    expect(policy).to match(/script-src 'self' 'nonce-[^']+'/)
    expect(policy).not_to include("unsafe")
  end
end
