require "rails_helper"

RSpec.describe User do
  it "normalizes and requires an address" do
    expect(build(:user, email_address: " Owner@Example.com ").email_address).to eq("owner@example.com")
    expect(build(:user, email_address: "nobody")).not_to be_valid
    expect(build(:user, email_address: "")).not_to be_valid
  end

  it "requires a password of 8 characters" do
    expect(build(:user, password: "1234567")).not_to be_valid
    expect(build(:user, password: "12345678")).to be_valid
  end

  it "allows only one user" do
    user = create(:user)

    expect(build(:user, email_address: "second@example.com")).not_to be_valid
    expect(user.update(email_address: "moved@example.com")).to be(true)
  end
end
