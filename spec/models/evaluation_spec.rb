require 'spec_helper'

describe Evaluation do
  context "factories" do
    context "default" do
      subject { build(:evaluation) }
      it { should be_valid }
    end
    context "suite" do
      subject { build(:suite_evaluation) }
      it { should be_valid }
    end
    context "template" do
      subject { build(:evaluation_template) }
      it { should be_valid }
    end
    context "generic" do
      subject { build(:generic_evaluation) }
      it { should be_valid }
    end
    context "numeric" do
      subject { build(:numeric_evaluation) }
      it { should be_valid }
    end
    context "boolean" do
      subject { build(:boolean_evaluation) }
      it { should be_valid }
    end
    context "grade" do
      subject { build(:grade_evaluation) }
      it { should be_valid }
    end
    context "invalid" do
      subject { build(:invalid_evaluation) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:type) }
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:description) }
    it { should allow_mass_assignment_of(:date) }
    it { should allow_mass_assignment_of(:max_result) }
    it { should allow_mass_assignment_of(:colors_serialized) }
    it { should allow_mass_assignment_of(:stanines_serialized) }
    it { should allow_mass_assignment_of(:red_min) }
    it { should allow_mass_assignment_of(:red_max) }
    it { should allow_mass_assignment_of(:yellow_min) }
    it { should allow_mass_assignment_of(:yellow_max) }
    it { should allow_mass_assignment_of(:green_min) }
    it { should allow_mass_assignment_of(:green_max) }
    1.upto(9).each do |i|
      it { should allow_mass_assignment_of(:"stanine#{i}_min") }
      it { should allow_mass_assignment_of(:"stanine#{i}_max") }
    end
    it { should allow_mass_assignment_of(:category_list) }
    it { should allow_mass_assignment_of(:target) }
    it { should allow_mass_assignment_of(:value_type) }
    it { should allow_mass_assignment_of(:color_for_true) }
    it { should allow_mass_assignment_of(:color_for_false) }
    ("a".."f").each do |grade|
      it { should allow_mass_assignment_of(:"color_for_grade_#{grade}") }
      it { should allow_mass_assignment_of(:"stanine_for_grade_#{grade}") }
    end
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should ensure_inclusion_of(:type).in_array(%w(suite template generic)) }
    it { should ensure_inclusion_of(:target).in_array(%w(all male female)) }
    it { should ensure_inclusion_of(:value_type).in_array(%w(numeric boolean grade)) }

    it { should validate_numericality_of(:max_result).only_integer }
    it { should_not allow_value(-1).for(:max_result) }

    context "numeric value type" do
      subject(:evaluation) { build(:numeric_evaluation,
        max_result: 30,
        _yellow:    10..20,
        _stanines:  [ 0..3, 4..6, 7..9, 10..12, 13..15, 16..18, 19..21, 22..24, 25..30 ]
      ) }

      Evaluation::VALID_COLORS.each do |color|
        it { should validate_numericality_of(:"#{color}_min").only_integer }
        it { should validate_numericality_of(:"#{color}_max").only_integer }
        it { should allow_value(nil).for(:"#{color}_min") }
        it { should allow_value(nil).for(:"#{color}_max") }

        it { should_not allow_value(-1).for(:"#{color}_min") }
        it { should_not allow_value(evaluation.send(:"#{color}_max") + 1).for(:"#{color}_min") }
        it { should_not allow_value(evaluation.send(:"#{color}_min") - 1).for(:"#{color}_max") }
        it { should_not allow_value(evaluation.max_result + 1).for(:"#{color}_max") }
      end

      1.upto(9) do |i|
        it { should validate_numericality_of(:"stanine#{i}_min").only_integer }
        it { should validate_numericality_of(:"stanine#{i}_max").only_integer }
        it { should allow_value(nil).for(:"stanine#{i}_min") }
        it { should allow_value(nil).for(:"stanine#{i}_max") }

        it { should_not allow_value(-1).for(:"stanine#{i}_min") }
        it { should_not allow_value(evaluation.send(:"stanine#{i}_max") + 1).for(:"stanine#{i}_min") }
        it { should_not allow_value(evaluation.send(:"stanine#{i}_min") - 1).for(:"stanine#{i}_max") }
        it { should_not allow_value(evaluation.max_result + 1).for(:"stanine#{i}_max") }
      end

      context "without stanines" do
        subject { build(:numeric_evaluation, _stanines: Array.new(9) )}
        it { should be_valid }
      end
    end

    context "boolean value type" do
      subject { build(:boolean_evaluation, colors: nil) }
      it      { should     ensure_inclusion_of(:color_for_true).in_array([:red, :yellow, :green]) }
      it      { should     ensure_inclusion_of(:color_for_false).in_array([:red, :yellow, :green]) }
      it      { should_not allow_value(nil).for(:color_for_true) }
      it      { should_not allow_value(nil).for(:color_for_false) }
    end

    context "grade value type" do
      subject { build(:grade_evaluation) }

      ("a".."f").each do |grade|
        it { should_not allow_value(0).for(:"color_for_grade_#{grade}") }
        it { should_not allow_value(4).for(:"color_for_grade_#{grade}") }
        it { should_not allow_value(0).for(:"stanine_for_grade_#{grade}") }
        it { should_not allow_value(10).for(:"stanine_for_grade_#{grade}") }
      end
    end

    context "with type" do
      context "suite" do
        subject { build(:suite_evaluation) }
        it { should     validate_presence_of(:suite) }
        it { should     validate_presence_of(:date) }
        it { should     allow_value("2013-04-29").for(:date) }
        it { should_not allow_value("201304-29").for(:date) }

        context "and with suite template" do
          subject { build(:suite_evaluation, suite: create(:suite, is_template: true)) }
          it { should_not validate_presence_of(:date) }
          it { should_not allow_value("2013-04-29").for(:date) }
          it { should_not allow_value("201304-29").for(:date) }
        end
      end
      context "template" do
        subject { build(:evaluation_template) }
        it { should_not validate_presence_of(:suite) }
        it { should_not allow_value(create(:suite)).for(:suite) }
        it { should_not validate_presence_of(:suite) }
        it { should_not allow_value("2013-04-29").for(:date) }
      end
      context "generic" do
        subject { build(:generic_evaluation) }
        it { should_not validate_presence_of(:suite) }
        it { should_not allow_value(create(:suite)).for(:suite) }
        it { should_not validate_presence_of(:suite) }
        it { should_not allow_value("2013-04-29").for(:date) }
      end
    end
  end

  describe ".parse_students_and_groups" do
    let(:suite)        { create(:suite) }
    let(:group)        { create(:group) }
    let(:participants) { create_list(:participant, 3, suite: suite) }
    let(:students)     { participants.collect(&:student) }

    before(:each) do
      group.students = [students.first, students.second ]
    end

    it "sets evaluation_participant_ids from student and group ids" do
      evaluation = build(:suite_evaluation, suite: suite, students_and_groups: "[],,s-#{students.third.id},g-#{group.id}")
      evaluation.valid?.should be_true
      evaluation.evaluation_participant_ids.should match_array(participants.collect(&:id))
    end

    it "clears evaluation_participants if students and groups are cleared" do
      evaluation = create(:suite_evaluation, suite: suite, students_and_groups: "[],,s-#{students.third.id},g-#{group.id}")
      evaluation.students_and_groups = nil
      evaluation.valid?.should be_true
      evaluation.evaluation_participants.should be_blank
    end

    it "does not touch evaluation_participants if the students and groups have not been explicitly cleared" do
      evaluation = create(:suite_evaluation, suite: suite, students_and_groups: "[],,s-#{students.third.id},g-#{group.id}")
      evaluation = Evaluation.find(evaluation.id)
      evaluation.valid?.should be_true
      evaluation.evaluation_participant_ids.should_not be_blank
    end
  end

  describe ".set_default_values_for_value_type" do
    context "for boolean values" do
      subject { create(:boolean_evaluation, max_result: nil) }
      its(:max_result) { should == 1 }
    end
    context "for grade values" do
      subject { create(:grade_evaluation, max_result: nil) }
      its(:max_result) { should == 5 }
    end
  end

  describe ".set_aliases_from_value_type" do
    context "for numeric value type" do
      subject { create(:numeric_evaluation) }
      its(:value_aliases) { should be_blank }
    end
    context "for boolean value type" do
      subject { create(:boolean_evaluation) }
      its(:value_aliases) { should == Evaluation::BOOLEAN_ALIASES }
    end
    context "for grade value type" do
      subject { create(:grade_evaluation) }
      its(:value_aliases) { should == Evaluation::GRADE_ALIASES }
    end
  end
  
  describe ".persist_colors_and_stanines" do
    let(:colors)   { nil }
    let(:stanines) { nil }
    context "for boolean value types" do
      subject      { create(:boolean_evaluation, colors: colors, color_for_true: :red, color_for_false: :green) }
      its(:colors) { should include("1" => "red") }
      its(:colors) { should include("0" => "green") }

      context "with explicitly set colors" do
        let(:colors) { { explicit: 1 } }
        its(:colors) { should == { "explicit" => 1 } }
      end
    end
    context "for grade value types" do
      subject        { create(
        :grade_evaluation,
        colors:          colors,
        stanines:        stanines,
        _grade_colors:   [ 1, 1, 2, 2, 3, 3 ],
        _grade_stanines: [ 2, 3, 5, 6, 7, 9 ]
      ) }
      its(:colors)   { should include("0" => 1) }
      its(:colors)   { should include("1" => 1) }
      its(:colors)   { should include("2" => 2) }
      its(:colors)   { should include("3" => 2) }
      its(:colors)   { should include("4" => 3) }
      its(:colors)   { should include("5" => 3) }

      its(:stanines) { should include("0" => 2) }
      its(:stanines) { should include("1" => 3) }
      its(:stanines) { should include("2" => 5) }
      its(:stanines) { should include("3" => 6) }
      its(:stanines) { should include("4" => 7) }
      its(:stanines) { should include("5" => 9) }

      context "with explicitly set colors and stanines" do
        let(:colors)   { { "explicit" => 1 } }
        let(:stanines) { { "explicit" => 2 } }
        its(:colors)   { should == { "explicit" => 1 } }
        its(:stanines) { should == { "explicit" => 2 } }
      end
    end
    context "for numeric value types" do
      let(:_yellow) { 10..20 }
      let(:_stanines) { [ 0..3, 4..6, 7..7, 8..12, 13..15, 16..18, 19..21, 22..24, 25..30 ] }
      subject { create(:numeric_evaluation,
        colors:     colors,
        stanines:   stanines,
        _yellow:    _yellow,
        max_result: 30,
        _stanines:  _stanines
      ) }

      its(:colors) { should include("red"    => { "min" => 0,  "max" => 9 }) }
      its(:colors) { should include("yellow" => { "min" => 10, "max" => 20 }) }
      its(:colors) { should include("green"  => { "min" => 21, "max" => 30 }) }

      its(:stanines) { should include("1" => { "min" => 0,  "max" => 3 } ) }
      its(:stanines) { should include("2" => { "min" => 4,  "max" => 6 } ) }
      its(:stanines) { should include("3" => { "min" => 7,  "max" => 7 } ) }
      its(:stanines) { should include("4" => { "min" => 8,  "max" => 12 } ) }
      its(:stanines) { should include("5" => { "min" => 13, "max" => 15 } ) }
      its(:stanines) { should include("6" => { "min" => 16, "max" => 18 } ) }
      its(:stanines) { should include("7" => { "min" => 19, "max" => 21 } ) }
      its(:stanines) { should include("8" => { "min" => 22, "max" => 24 } ) }
      its(:stanines) { should include("9" => { "min" => 25, "max" => 30 } ) }

      context "with only a yellow range" do
        let(:_yellow) { 0..30 }
        its(:colors)  { should include("yellow" => { "min" => 0, "max" => 30 }) }
        its(:colors)  { should_not have_key("red") }
        its(:colors)  { should_not have_key("green") }
      end
      context "with overlapping stanines" do
        let(:_stanines) { [ 0..3, 4..6, 7..9, 9..9, 9..9, 10..18, 19..21, 22..30 ] }
        its(:stanines) { should include("1" => { "min" => 0,  "max" => 3 } ) }
        its(:stanines) { should include("2" => { "min" => 4,  "max" => 6 } ) }
        its(:stanines) { should include("3" => { "min" => 7,  "max" => 9 } ) }
        its(:stanines) { should include("4" => { "min" => 9,  "max" => 9 } ) }
        its(:stanines) { should include("5" => { "min" => 9,  "max" => 9 } ) }
        its(:stanines) { should include("6" => { "min" => 10, "max" => 18 } ) }
        its(:stanines) { should include("7" => { "min" => 19, "max" => 21 } ) }
        its(:stanines) { should include("8" => { "min" => 22, "max" => 30 } ) }
      end

      context "with explicitly set colors and stanines" do
        let(:colors)   { { "explicit" => 1 } }
        let(:stanines) { { "explicit" => 2 } }
        its(:colors)   { should == { "explicit" => 1 } }
        its(:stanines) { should == { "explicit" => 2 } }
      end
    end
  end

  describe ".colors_serialized" do
    subject                 { create(:evaluation, colors: colors, _yellow: nil) }

    context "with values" do
      let(:colors)            { { foo: 1, bar: 2 } }
      its(:colors_serialized) { should == colors.to_json }
    end
    context "with nil" do
      let(:colors)            { nil }
      its(:colors_serialized) { should be_nil }
    end
  end
  describe ".colors_serialized=" do
    let(:evaluation) { create(:evaluation, colors: nil, _yellow: nil) }
    before(:each)    { evaluation.colors_serialized = value }
    subject          { evaluation }

    context "with values" do
      let(:raw_value) { { "foo" => 1, "bar" => 2 } }
      let(:value)     { raw_value.to_json }
      its(:colors)    { should == raw_value }
    end
    context "with nil" do
      let(:value)  { nil }
      its(:colors) { should be_nil }
    end
  end
  describe ".stanines_serialized" do
    subject                 { create(:evaluation, stanines: stanines) }

    context "with values" do
      let(:stanines)            { { foo: 1, bar: 2 } }
      its(:stanines_serialized) { should == stanines.to_json }
    end
    context "with nil" do
      let(:stanines)            { nil }
      its(:stanines_serialized) { should be_nil }
    end
  end
  describe ".stanines_serialized=" do
    let(:evaluation) { create(:evaluation, stanines: nil) }
    before(:each)    { evaluation.stanines_serialized = value }
    subject          { evaluation }

    context "with values" do
      let(:raw_value) { { "foo" => 1, "bar" => 2 } }
      let(:value)     { raw_value.to_json }
      its(:stanines)    { should == raw_value }
    end
    context "with nil" do
      let(:value)  { nil }
      its(:stanines) { should be_nil }
    end
  end

  describe ".has_regular_suite?" do
    context "with no suite" do
      subject { build(:evaluation, suite: nil).has_regular_suite? }
      it { should be_false }
    end
    context "with template suite" do
      subject { build(:suite_evaluation, suite: create(:suite, is_template: true)).has_regular_suite? }
      it { should be_false }
    end
    context "with regular suite" do
      subject { build(:suite_evaluation, suite: create(:suite, is_template: false)).has_regular_suite? }
      it { should be_true }
    end
    context "with wrong type" do
      subject { build(:suite_evaluation, suite: create(:suite, is_template: false), type: :template).has_regular_suite? }
      it { should be_false }
    end
  end

  describe ".color_for" do
    let(:value)      { nil }
    subject          { evaluation.color_for(value) }

    context "for numeric value types" do
      let(:evaluation) { create(:numeric_evaluation, _yellow: 10..20, max_result: 30) }

      it { should be_nil }

      context "with red value" do
        let(:value) { 9 }
        it { should == :red }
      end
      context "with yellow value, lower bound" do
        let(:value) { 10 }
        it { should == :yellow }
      end
      context "with yellow value, upper bound" do
        let(:value) { 20 }
        it { should == :yellow }
      end
      context "with green value" do
        let(:value) { 21 }
        it { should == :green }
      end

      context "with only a yellow range" do
        let(:evaluation) { create(:numeric_evaluation, _yellow: 0..30, max_result: 30) }

        context "and lower bound" do
          let(:value) { 0 }
          it { should == :yellow }
        end
        context "and upper bound" do
          let(:value) { 30 }
          it { should == :yellow }
        end
      end
    end
    context "for boolean value types" do
      let(:evaluation) { create(:boolean_evaluation, color_for_false: :yellow, color_for_true: :red) }
      it { should be_nil }
      context "with true" do
        let(:value) { 1 }
        it { should == :red }
      end
      context "with false" do
        let(:value) { 0 }
        it { should == :yellow }
      end
    end
    context "for grade value types" do
      let(:evaluation) { create(:grade_evaluation, _grade_colors: [1, 1, 2, 2, 3, 3]) }
      it { should be_nil }
      context "with A" do
        let(:value) { 5 }
        it { should == :green }
      end
      context "with B" do
        let(:value) { 4 }
        it { should == :green }
      end
      context "with C" do
        let(:value) { 3 }
        it { should == :yellow }
      end
      context "with D" do
        let(:value) { 2 }
        it { should == :yellow }
      end
      context "with E" do
        let(:value) { 1 }
        it { should == :red }
      end
      context "with F" do
        let(:value) { 0 }
        it { should == :red }
      end
    end
  end
  describe ".stanine_for" do
    let(:value)      { nil }
    subject          { evaluation.stanine_for(value) }

    context "for numeric value types" do
      let(:_stanines) { [ 0..10, 11..20, 21..30, 31..40, 41..50, 51..60, 61..70, 71..80, 81..90 ] }
      let(:evaluation) { create(:evaluation, max_result: 90, _stanines: _stanines) }

      it { should be_nil }

      # Boundaries for the stanine values given the stanine limits above
      {
        1 => [0,10],
        2 => [11,20],
        3 => [21,30],
        4 => [31,40],
        5 => [41,50],
        6 => [51,60],
        7 => [61,70],
        8 => [71,80],
        9 => [81,90]
      }.each_pair do |stanine, values|
        context "stanine #{stanine}, lower bound" do
          let(:value) { values.first }
          it          { should == stanine }
        end
        context "stanine #{stanine}, upper bound" do
          let(:value) { values.second }
          it          { should == stanine }
        end
      end

      context "with overlapping stanines" do
        let(:_stanines) { [ 0..10, 11..20, 21..30, 31..40, 40..40, 40..40, 41..70, 71..80, 81..90 ]}
        context "giving smallest stanine" do
          let(:value) { 40 }
          it          { should == 4 }
        end
        context "giving the correct stanine below" do
          let(:value) { 39 }
          it          { should == 4 }
        end
        context "giving the correct stanine above" do
          let(:value) { 41 }
          it          { should == 7 }
        end
      end

      context "without stanines" do
        let(:_stanines) { nil }
        let(:value)          { 123 }
        it                   { should be_nil }
      end
    end

    context "for grade value types" do
      let (:evaluation) { create(:grade_evaluation, _grade_stanines: [2, 2, 3, 5, 7, 9]) }
      it { should be_nil }
      context "with A" do
        let(:value) { 5 }
        it { should == 9 }
      end
      context "with B" do
        let(:value) { 4 }
        it { should == 7 }
      end
      context "with C" do
        let(:value) { 3 }
        it { should == 5 }
      end
      context "with D" do
        let(:value) { 2 }
        it { should == 3 }
      end
      context "with E" do
        let(:value) { 1 }
        it { should == 2 }
      end
      context "with F" do
        let(:value) { 0 }
        it { should == 2 }
      end
    end
  end

  describe ".result_for" do
    let(:students)   { create_list(:student, 3) }
    let(:student)    { students.second }
    let(:evaluation) { create(:evaluation) }
    before           { students.each_with_index { |student, i| create(:result, evaluation: evaluation, student: student, value: (i+1)*10) } }

    it "returns the correct result" do
      evaluation.result_for(student).value.should == 20
    end
    it "returns nil when the result cannot be found" do
      evaluation.result_for(create(:student)).should be_nil
    end
  end

  describe ".stanines?" do
    it "returns true if there are any stanine values set" do
      create(:evaluation, _stanines: Array.new(9, 1..1)).stanines?.should be_true
    end
    it "returns false if no stanine values are set" do
      create(:evaluation, _stanines: Array.new(9)).stanines?.should be_false
    end
  end

  describe ".participants" do
    let(:target)               { :all }
    let(:suite)                { create(:suite) }
    let!(:male_participants)   { create_list(:male_participant,   1, suite: suite) }
    let!(:female_participants) { create_list(:female_participant, 4, suite: suite) }
    let(:suite_participants)   { male_participants + female_participants }
    subject(:evaluation)       { create(:suite_evaluation, suite: suite, target: target) }

    its(:participants) { should match_array(suite_participants) }

    context "limited by gender" do
      let(:target) { :female }
      its(:participants) { should match_array(female_participants) }
    end

    context "with evaluation participants" do
      before(:each) do
        evaluation.evaluation_participants << female_participants.first
        evaluation.evaluation_participants << male_participants.first
      end

      its(:participants) { should match_array([ female_participants.first, male_participants.first ]) }
    end
  end

  describe ".participant_count" do
    let(:target)               { :all }
    let(:suite)                { create(:suite) }
    let!(:male_participants)   { create_list(:male_participant,   1, suite: suite) }
    let!(:female_participants) { create_list(:female_participant, 4, suite: suite) }
    let(:participants)         { male_participants + female_participants }
    subject(:evaluation)       { create(:suite_evaluation, suite: suite, target: target) }

    its(:participant_count) { should == participants.length }

    context "limited by gender" do
      let(:target) { :female }
      its(:participant_count) { should == female_participants.length }
    end
  end

  describe ".students_and_groups_select2_data" do
    let(:suite)        { create(:suite) }
    let(:participants) { create_list(:participant, 3, suite: suite) }
    let(:evaluation)   { create(:suite_evaluation, suite: suite) }

    before(:each) do
      evaluation.evaluation_participants = participants
    end

    subject { evaluation.students_and_groups_select2_data }

    its(:length) { should == 3 }

    it { should include({ id: "s-#{participants.first.student_id}",  text: participants.first.student.name }) }
    it { should include({ id: "s-#{participants.second.student_id}", text: participants.second.student.name }) }
    it { should include({ id: "s-#{participants.third.student_id}",  text: participants.third.student.name }) }
  end

  describe ".users_select2_data" do
    let(:users)          { create_list(:user, 2) }
    subject(:evaluation) { create(:suite_evaluation, users: users) }

    its(:users_select2_data) { should have(2).items }
    its(:users_select2_data) { should include(id: users.first.id,  text: "#{users.first.name}, #{users.first.email}") }
    its(:users_select2_data) { should include(id: users.second.id, text: "#{users.second.name}, #{users.second.email}") }
  end

  describe ".result_distribution" do
    let(:target)               { :all }
    let(:suite)                { create(:suite) }
    let!(:male_participants)   { create_list(:male_participant,   1, suite: suite) }
    let!(:female_participants) { create_list(:female_participant, 4, suite: suite) }
    let(:participants)         { male_participants + female_participants }
    let(:evaluation)           { create(:suite_evaluation, suite: suite, max_result: 10, _yellow: 4..7, target: target) }

    context "with all types" do
      before(:each) do
        create(:result, student: participants[0].student, evaluation: evaluation, value: 1) # red
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
        create(:result, student: participants[3].student, evaluation: evaluation, value: 8) # green
      end

      subject { evaluation.result_distribution }

      it { should include(not_reported: 20.0) }
      it { should include(red:          20.0) }
      it { should include(yellow:       40.0) }
      it { should include(green:        20.0) }
      it { should include(absent:       0) }
    end

    context "without a color" do
      before(:each) do
        create(:result, student: participants[0].student, evaluation: evaluation, value: 9) # green
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
        create(:result, student: participants[3].student, evaluation: evaluation, value: 8) # green
      end

      subject { evaluation.result_distribution }

      it { should include(not_reported: 20.0) }
      it { should include(red:          0) }
      it { should include(yellow:       40.0) }
      it { should include(green:        40.0) }
      it { should include(absent:       0) }
    end

    context "without results" do
      subject { create(:evaluation).result_distribution }
      it      { should be_blank }
    end

    context "limited by gender" do
      let(:target) { :female }

      before(:each) do
        create(:result, student: female_participants[0].student, evaluation: evaluation, value: 1) # red
        create(:result, student: female_participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: female_participants[2].student, evaluation: evaluation, value: 8) # green
        create(:result, student: female_participants[3].student, evaluation: evaluation, value: 9) # green
      end

      subject { evaluation.result_distribution }

      it { should include(not_reported: 0) }
      it { should include(red:          25.0) }
      it { should include(yellow:       25.0) }
      it { should include(green:        50.0) }
      it { should include(absent:       0) }
    end

    context "with absent results" do
      before(:each) do
        create(:result, student: participants[0].student, evaluation: evaluation, value: nil, absent: true) # absent
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
        create(:result, student: participants[3].student, evaluation: evaluation, value: 8) # green
      end

      subject { evaluation.result_distribution }

      it { should include(not_reported: 20.0) }
      it { should include(red:          0) }
      it { should include(yellow:       40.0) }
      it { should include(green:        20.0) }
      it { should include(absent:       20.0) }
    end
  end

  describe ".stanine_distribution" do
    subject(:evaluation) { create(:evaluation,
      max_result: 8,
      _yellow: 3..5,
      _stanines: [ 0..0, 1..1, 2..2, 3..3, 4..4, 5..5, 6..6, 7..7, 8..8 ]
    ) }

    before(:each) do
      # No 5, two 4:s (stanine)
      [0, 1, 2, 3, 3, 5, 6, 7, 8].each do |value|
        create(:result, evaluation: evaluation, value: value)
      end
    end

    its(:stanine_distribution) { should have(8).items }
    its(:stanine_distribution) { should include(1 => 1) }
    its(:stanine_distribution) { should include(2 => 1) }
    its(:stanine_distribution) { should include(3 => 1) }
    its(:stanine_distribution) { should include(4 => 2) }
    its(:stanine_distribution) { should include(6 => 1) }
    its(:stanine_distribution) { should include(7 => 1) }
    its(:stanine_distribution) { should include(8 => 1) }
    its(:stanine_distribution) { should include(9 => 1) }
    its(:stanine_distribution) { should_not have_key(5) }
  end

  describe ".alias_for" do
    let(:aliases)    { { 1 => "foo", 2 => "bar" } }
    let(:evaluation) { create(:evaluation, value_aliases: aliases) }

    it "converts a raw value to its alias" do
      evaluation.alias_for(1).should == "foo"
    end
    it "returns the raw value if there is no alias" do
      evaluation.alias_for(3).should == 3
    end
    context "without aliases" do
      let(:aliases) { nil }
      it "returns the raw value" do
        evaluation.alias_for(1).should == 1
      end
    end
  end

  describe ".update_status!" do
    let!(:suite)           { create(:suite) }
    let(:num_participants) { 0 }
    let(:num_results)      { 0 }
    let!(:evaluation)      { create(:suite_evaluation, suite: suite) }

    before(:each) do
      participants = 1.upto(num_participants).collect { |i| create(:participant, suite: suite) }
      results      = 1.upto(num_results).collect      { |i| create(:result, evaluation: evaluation, student: participants[i-1].student) }
      evaluation.update_status!
    end

    subject { evaluation }

    its(:status) { should == "empty" }

    context "with participants" do
      let(:num_participants) { 3 }
      its(:status)           { should == "empty" }

      context "and complete results" do
        let(:num_results) { 3 }
        its(:status)      { should == "complete" }
      end
      context "and partial results" do
        let(:num_results) { 2 }
        its(:status)      { should == "partial" }
      end
    end
  end

  describe "#new_from_template" do
    let(:template) { create(:evaluation_template, category_list: "foo, bar, baz", target: :male) }
    subject        { Evaluation.new_from_template(template) }

    its(:template_id)   { should == template.id }
    its(:name)          { should == template.name }
    its(:description)   { should == template.description }
    its(:colors)        { should == template.colors }
    its(:stanines)      { should == template.stanines }
    its(:max_result)    { should == template.max_result }
    its(:category_list) { should == template.category_list }
    its(:target)        { should == template.target }
    its(:type)          { should == template.type }

    context "with attrs" do
      subject { Evaluation.new_from_template(template, { suite_id: 1, name: "Overridden" }) }
      its(:suite_id) { should == 1 }
      its(:name)     { should == "Overridden" }
    end
  end

  describe "#overdue" do
    let(:suite)                  { create(:suite) }
    let!(:participants)          { create_list(:participant, 2, suite: suite) }
    let!(:wrong_type)            { create_list(:generic_evaluation, 2) + create_list(:evaluation_template, 2) }
    let!(:upcoming)              { create_list(:suite_evaluation, 3, suite: suite, date: Date.today) }
    let!(:with_complete_results) { create_list(:suite_evaluation, 3, suite: suite, date: Date.yesterday) }
    let!(:with_partial_results)  { create_list(:suite_evaluation, 3, suite: suite, date: Date.yesterday) }
    let!(:without_results)       { create_list(:suite_evaluation, 3, suite: suite, date: Date.yesterday) }

    before(:each) do
      with_complete_results.each do |e|
        create(:result, evaluation: e, student: participants.first.student)
        create(:result, evaluation: e, student: participants.second.student)
      end
      with_partial_results.each do |e|
        create(:result, evaluation: e, student: participants.first.student)
      end
    end

    subject(:result) { Evaluation.overdue.all }

    it { should have(6).items }
    it { should match_array(with_partial_results + without_results) }
  end
  describe "#upcoming" do
    let!(:passed)   { create_list(:suite_evaluation, 3, date: Date.yesterday) }
    let!(:upcoming) { create_list(:suite_evaluation, 3, date: Date.today) }
    subject         { Evaluation.upcoming.all }
    it              { should have(3).items }
    it              { should match_array(upcoming) }
  end

  describe "#where_suite_contributor" do
    let(:user)                     { create(:superuser) }
    let(:contributed_suite)        { create(:suite) }
    let(:managed_suite)            { create(:suite) }
    let(:not_allowed_suite)        { create(:suite) }
    let!(:allowed_evaluations)     { create_list(:suite_evaluation, 3, suite: contributed_suite) + create_list(:suite_evaluation, 3, suite: managed_suite) }
    let!(:not_allowed_evaluations) { create_list(:suite_evaluation, 3, suite: not_allowed_suite) }

    before(:each) do
      user.add_role :suite_contributor, contributed_suite
      user.add_role :suite_manager,     managed_suite
    end

    subject { Evaluation.where_suite_contributor(user).all }

    it { should have(6).items }
    it { should match_array(allowed_evaluations) }
  end

  describe "#with_stanines" do
    let!(:without_stanines)      { create(:boolean_evaluation, stanines: nil) }
    let!(:with_numeric_stanines) { create(:numeric_evaluation, _stanines: Array.new(9, 1..1)) }
    let!(:with_grade_stanines)   { create(:grade_evaluation,   _grade_stanines: [ 1, 3, 4, 5, 6, 9 ]) }

    subject { Evaluation.with_stanines.all }

    it { should have(2).items }
    it { should match_array([with_numeric_stanines, with_grade_stanines]) }
  end

  describe "#without_explicit_users" do
    let!(:user)                   { create(:user) }
    let!(:with_explicit_users)    { create_list(:suite_evaluation, 2) }
    let!(:without_explicit_users) { create_list(:suite_evaluation, 3) }

    before(:each) { with_explicit_users.each { |e| e.users << user } }

    subject { Evaluation.without_explicit_users.all }

    it { should have(3).items }
    it { should match_array(without_explicit_users) }
  end
end
