FactoryBot.define do
  factory :universe_setting do
    name { "Knighthood" }
    start_date { "1000-01-01" }
    end_date { "2320-12-31" }
    current_day { "2300-09-25" }
  end

  factory :group do
    sequence(:name) { |n| "Group #{n}" }
  end

  factory :character do
    sequence(:name) { |n| "Character #{n}" }
    birth_date { "2270-01-01" }
  end

  factory :event do
    sequence(:name) { |n| "Event #{n}" }
    start_date { "2290-01-01" }
  end
end
