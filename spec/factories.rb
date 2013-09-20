FactoryGirl.define do
  factory :user do
    sequence(:name)       { |i| "User %09d" % i }
    sequence(:email)      { |i| "user%09d@example.com" % i }
    password              "password"
    password_confirmation { password }
    registered_yubikey    "abcdefghijkl"
    invisible             false
    active_instance       nil

    factory :admin do
      after(:create) { |user| user.add_role :admin }
    end
    factory :superuser do
      after(:create) { |user| user.add_role :superuser }
    end
    factory(:invalid_user) do
      name nil
    end
    factory(:invisible_user) do
      invisible true
    end
  end

  factory :student do
    sequence(:personal_id) { |i| "%06d" % i }
    first_name             "Student"
    sequence(:last_name)   { |i| "%09d" % i }
    gender                 :male
    data                   nil

    factory :invalid_student do
      first_name nil
      last_name  nil
    end
  end

  factory :group do
    sequence(:name) { |i| "Group %09d" % i }
    parent          nil

    factory :invalid_group do
      name nil
    end
  end

  factory :suite do
    template            nil
    sequence(:name)     { |i| "Suite %09d" % i }
    is_template         false
    generic_evaluations nil

    factory :invalid_suite do
      name nil
    end
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
    target          :all
    value_aliases   nil
    value_type      :numeric
    colors          nil
    stanines        nil
    status          :empty

    ignore do
      _yellow   15..35
      _red      nil
      _green    nil
      _stanines nil # [0..7, 8..12, 13..17, 18..22, 23..27, 28..32, 33..37, 38..42, 43..50]
    end

    red_min    { _red ? _red.min : (_yellow && _yellow.min > 0 ? 0 : nil) }
    red_max    { _red ? _red.max : (_yellow && _yellow.min > 0 ? _yellow.min - 1 : nil) }
    yellow_min { _yellow ? _yellow.min : nil }
    yellow_max { _yellow ? _yellow.max : nil }
    green_min  { _green ? _green.min : (_yellow && _yellow.max < max_result ? _yellow.max + 1 : nil) }
    green_max  { _green ? _green.max : (_yellow && _yellow.max < max_result ? max_result : nil) }

    stanine1_min { _stanines ? _stanines[0].try(:min) : nil }
    stanine1_max { _stanines ? _stanines[0].try(:max) : nil }
    stanine2_min { _stanines ? _stanines[1].try(:min) : nil }
    stanine2_max { _stanines ? _stanines[1].try(:max) : nil }
    stanine3_min { _stanines ? _stanines[2].try(:min) : nil }
    stanine3_max { _stanines ? _stanines[2].try(:max) : nil }
    stanine4_min { _stanines ? _stanines[3].try(:min) : nil }
    stanine4_max { _stanines ? _stanines[3].try(:max) : nil }
    stanine5_min { _stanines ? _stanines[4].try(:min) : nil }
    stanine5_max { _stanines ? _stanines[4].try(:max) : nil }
    stanine6_min { _stanines ? _stanines[5].try(:min) : nil }
    stanine6_max { _stanines ? _stanines[5].try(:max) : nil }
    stanine7_min { _stanines ? _stanines[6].try(:min) : nil }
    stanine7_max { _stanines ? _stanines[6].try(:max) : nil }
    stanine8_min { _stanines ? _stanines[7].try(:min) : nil }
    stanine8_max { _stanines ? _stanines[7].try(:max) : nil }
    stanine9_min { _stanines ? _stanines[8].try(:min) : nil }
    stanine9_max { _stanines ? _stanines[8].try(:max) : nil }

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

    factory :numeric_evaluation do
    end
    factory :boolean_evaluation do
      value_type      :boolean
      max_result      1
      _yellow         nil
      _stanines       nil
      color_for_false :red
      color_for_true  :green
    end
    factory :grade_evaluation do
      value_type :grade
      _yellow    nil
      _stanines  nil

      # 1 = red, 2 = yellow, 3 = green
      ignore do
        # F, E, D, C, B, A
        _grade_colors [ 1, 1, 2, 2, 3, 3 ]
      end
      color_for_grade_a { _grade_colors[5] }
      color_for_grade_b { _grade_colors[4] }
      color_for_grade_c { _grade_colors[3] }
      color_for_grade_d { _grade_colors[2] }
      color_for_grade_e { _grade_colors[1] }
      color_for_grade_f { _grade_colors[0] }

      ignore do
        # F, E, D, C, B, A
        _grade_stanines nil
      end

      stanine_for_grade_a { _grade_stanines ? _grade_stanines[5] : nil }
      stanine_for_grade_b { _grade_stanines ? _grade_stanines[4] : nil }
      stanine_for_grade_c { _grade_stanines ? _grade_stanines[3] : nil }
      stanine_for_grade_d { _grade_stanines ? _grade_stanines[2] : nil }
      stanine_for_grade_e { _grade_stanines ? _grade_stanines[1] : nil }
      stanine_for_grade_f { _grade_stanines ? _grade_stanines[0] : nil }
    end
    factory :invalid_evaluation do
      name nil
    end
  end

  factory :result do
    evaluation
    student
    value   25
    color   nil
    stanine nil
    absent  false
  end

  factory :meeting do
    suite
    sequence(:name) { |i| "Meeting %09d" % i }
    date            Date.today
    agenda          nil
    completed       false
    notes           nil

    factory :invalid_meeting do
      name nil
    end
  end

  factory :activity do
    suite
    meeting         nil
    type            :action
    status          :open
    sequence(:name) { |i| "Activity %09d" % i }
    start_date      nil
    end_date        nil
    description     nil
    notes           nil

    factory :action_activity do
    end
    factory :inquiry_activity do
      type :inquiry
    end
    factory :invalid_activity do
      name nil
    end
  end

  factory :instruction do
    sequence(:title) { |i| "Instruction %09d" % i }
    for_page         "/foo/bar"
    film             "foo"
    description      "foo"

    factory :invalid_instruction do
      title nil
    end
  end

  factory :setting do
    association :customizer,   factory: :user
    association :customizable, factory: :suite

    data nil
  end

  factory :table_state do
    association :base, factory: :suite

    sequence(:name) { |i| "Table state %09d" % i }
    data            nil

    factory :invalid_table_state do
      name nil
    end
  end

  factory :instance do
    sequence(:name)       { |i| "Instance %09d" % i }

    factory :invalid_instance do
      name nil
    end
  end
end
