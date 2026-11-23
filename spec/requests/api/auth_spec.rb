require "rails_helper"
require "open3"

RSpec.describe "API authorization" do
  def request_with(headers = {})
    get "/api/groups", headers:
  end

  context "with a key configured" do
    before { allow(Rails.configuration.x).to receive(:api_key).and_return("secret") }

    it "refuses a request without a key" do
      request_with

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to eq('{"error":"Unauthorized"}')
    end

    it "refuses other keys and schemes" do
      ["Bearer wrong", "Bearer secret2", "Bearer ", "bearer secret", "Basic secret", "secret"].each do |value|
        request_with("Authorization" => value)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "refuses a matching Referer without a key" do
      request_with("Referer" => "http://www.example.com/events")

      expect(response).to have_http_status(:unauthorized)
    end

    it "accepts the key" do
      request_with("Authorization" => "Bearer secret")

      expect(response).to have_http_status(:ok)
    end

    it "refuses before reading the body" do
      post "/api/groups", params: "{", headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      expect(Group.count).to eq(0)
    end
  end

  it "does not check without a key configured outside production" do
    allow(Rails.configuration.x).to receive(:api_key).and_return(nil)
    request_with

    expect(response).to have_http_status(:ok)
  end

  describe "booting production" do
    def boot(env)
      command = [Rails.root.join("bin/rails").to_s, "runner", "puts :booted"]
      base = { "RAILS_ENV" => "production", "SECRET_KEY_BASE" => "x" * 64, "API_KEY" => nil,
               "SECRET_KEY_BASE_DUMMY" => nil, "DATABASE_URL" => "postgresql://localhost/none" }
      Open3.capture2e(base.merge(env), *command)
    end

    it "fails without API_KEY and names it" do
      output, status = boot({})

      expect(status).not_to be_success
      expect(output).to include("API_KEY")
      expect(boot("API_KEY" => "").last).not_to be_success
    end

    it "works with API_KEY" do
      output, status = boot("API_KEY" => "secret")

      expect(output).to include("booted")
      expect(status).to be_success
    end
  end
end
