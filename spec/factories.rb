FactoryGirl.define do
  factory :user do
    sequence(:email)      { |i| "user#{i}@example.com" }
    password              "password"
    password_confirmation { password }
  end

  factory :student do
    sequence(:name) { |i| "Student #{i}" }
  end

  factory :suite do
    sequence(:name) { |i| "Suite #{i}" }
  end

  factory :evaluation do
    suite
    sequence(:name) { |i| "Evaluation #{i}" }
    max_result      50
    red_below       15
    green_above     35
  end
end
