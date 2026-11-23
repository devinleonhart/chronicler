FactoryBot.define do
  factory :user do
    email_address { "owner@example.com" }
    password { "correct horse" }
  end
end
