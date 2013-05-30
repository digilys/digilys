FactoryGirl.define do
  factory :user do
    sequence(:name)       { |i| "User %09d" % i }
    sequence(:email)      { |i| "user%09d@example.com" % i }
    password              "password"
    password_confirmation { password }

    factory :admin do
      after(:create) { |user| user.add_role :admin }
    end
  end

  factory :student do
    sequence(:personal_id) { |i| "%06d" % i }
    first_name             "Student"
    sequence(:last_name)   { |i| "%09d" % i }
    gender                 :male
    data                   nil
  end

  factory :group do
    sequence(:name) { |i| "Group %09d" % i }
    parent          nil
  end

  factory :suite do
    template            nil
    sequence(:name)     { |i| "Suite %09d" % i }
    is_template         false
    generic_evaluations nil
  end

  factory :participant do
    student
    suite

    factory :male_participant do
      student { create(:student, gender: :male) }
    end
    factory :female_participant do
      student { create(:student, gender: :female) }
    end
  end

  factory :evaluation do
    template        nil
    suite           nil
    type            :generic
    sequence(:name) { |i| "Evaluation %09d" % i }
    description     "Description"
    date            nil
    max_result      50
    red_below       15
    green_above     35
    target          :all
    value_aliases   nil

    ignore do
      stanines      [7, 12, 17, 22, 27, 32, 37, 42]
    end

    stanine1        { stanines ? stanines[0] : nil }
    stanine2        { stanines ? stanines[1] : nil }
    stanine3        { stanines ? stanines[2] : nil }
    stanine4        { stanines ? stanines[3] : nil }
    stanine5        { stanines ? stanines[4] : nil }
    stanine6        { stanines ? stanines[5] : nil }
    stanine7        { stanines ? stanines[6] : nil }
    stanine8        { stanines ? stanines[7] : nil }

    factory :suite_evaluation do
      suite
      type  :suite
      date  { suite.is_template ? nil : Date.today }
    end
    factory :evaluation_template do
      type :template
    end
    factory :generic_evaluation do
    end
  end

  factory :result do
    evaluation
    student
    value   25
    color   nil
    stanine nil
  end

  factory :meeting do
    suite
    sequence(:name) { |i| "Meeting %09d" % i }
    date            Date.today
    agenda          nil
    completed       false
    notes           nil
  end

  factory :activity do
    suite
    meeting         nil
    type            :action
    status          :open
    sequence(:name) { |i| "Activity %09d" % i }
    description     nil
    notes           nil

    factory :action_activity do
    end
    factory :inquiry_activity do
      type :inquiry
    end
  end
end
