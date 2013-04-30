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

  factory :participant do
    student
    suite
  end

  factory :evaluation do
    suite
    sequence(:name) { |i| "Evaluation #{i}" }
    date            Date.today
    max_result      50
    red_below       15
    green_above     35

    ignore do
      stanines      [7, 12, 17, 22, 27, 32, 37, 42]
    end

    stanine1        { stanines[0] }
    stanine2        { stanines[1] }
    stanine3        { stanines[2] }
    stanine4        { stanines[3] }
    stanine5        { stanines[4] }
    stanine6        { stanines[5] }
    stanine7        { stanines[6] }
    stanine8        { stanines[7] }
  end

  factory :result do
    evaluation
    student
    value 25
  end

  factory :meeting do
    suite
    sequence(:name) { |i| "Meeting #{i}" }
    date            Date.today
    completed       false
    notes           nil
  end
end
