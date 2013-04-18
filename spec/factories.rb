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
end
