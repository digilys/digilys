FactoryGirl.define do
  factory :user do
    sequence(:name)       { |i| "User %09d" % i }
    sequence(:email)      { |i| "user%09d@example.com" % i }
    password              "password"
    password_confirmation { password }

    factory :admin do
      after(:create) { |user| user.add_role :admin }
    end
    factory :superuser do
      after(:create) { |user| user.add_role :superuser }
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
    value_type      :numeric
    colors          nil
    stanines        nil
    status          :empty

    ignore do
      stanine_values [7, 12, 17, 22, 27, 32, 37, 42]
    end

    stanine1        { stanine_values ? stanine_values[0] : nil }
    stanine2        { stanine_values ? stanine_values[1] : nil }
    stanine3        { stanine_values ? stanine_values[2] : nil }
    stanine4        { stanine_values ? stanine_values[3] : nil }
    stanine5        { stanine_values ? stanine_values[4] : nil }
    stanine6        { stanine_values ? stanine_values[5] : nil }
    stanine7        { stanine_values ? stanine_values[6] : nil }
    stanine8        { stanine_values ? stanine_values[7] : nil }

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
      value_type     :boolean
      max_result     1
      red_below      nil
      green_above    nil
      stanine_values nil
      colors         ({ "0" => "red", "1" => "green" })
    end
    factory :grade_evaluation do
      value_type        :grade

      # 1 = red, 2 = yellow, 3 = green
      ignore do
        # F, E, D, C, B, A
        color_for_grades [ 1, 1, 2, 2, 3, 3 ]
      end
      color_for_grade_a { color_for_grades[5] }
      color_for_grade_b { color_for_grades[4] }
      color_for_grade_c { color_for_grades[3] }
      color_for_grade_d { color_for_grades[2] }
      color_for_grade_e { color_for_grades[1] }
      color_for_grade_f { color_for_grades[0] }

      ignore do
        stanines nil
        # F, E, D, C, B, A
        stanine_for_grades nil
      end

      stanine_for_grade_a { stanine_for_grades ? stanine_for_grades[5] : nil }
      stanine_for_grade_b { stanine_for_grades ? stanine_for_grades[4] : nil }
      stanine_for_grade_c { stanine_for_grades ? stanine_for_grades[3] : nil }
      stanine_for_grade_d { stanine_for_grades ? stanine_for_grades[2] : nil }
      stanine_for_grade_e { stanine_for_grades ? stanine_for_grades[1] : nil }
      stanine_for_grade_f { stanine_for_grades ? stanine_for_grades[0] : nil }
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
    date            nil
    description     nil
    notes           nil

    factory :action_activity do
    end
    factory :inquiry_activity do
      type :inquiry
    end
  end
end
