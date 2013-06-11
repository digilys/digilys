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
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:type) }
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:description) }
    it { should allow_mass_assignment_of(:date) }
    it { should allow_mass_assignment_of(:max_result) }
    it { should allow_mass_assignment_of(:red_below) }
    it { should allow_mass_assignment_of(:green_above) }
    1.upto(8).each do |i|
      it { should allow_mass_assignment_of(:"stanine#{i}") }
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
      subject { build(:numeric_evaluation) }

      it { should validate_numericality_of(:red_below).only_integer }
      it { should validate_numericality_of(:green_above).only_integer }

      it { should_not allow_value(nil).for(:red_below) }
      it { should_not allow_value(nil).for(:green_above) }

      1.upto(8) do |i|
        it { should validate_numericality_of(:"stanine#{i}").only_integer }
      end

      context "limit ranges" do
        subject { build(:evaluation, value_type: :numeric, max_result: 50, red_below: 20, green_above: 30) }
        it { should_not allow_value(-1).for(:red_below) }
        it { should_not allow_value(51).for(:green_above) }
        it { should_not allow_value(19).for(:green_above) }
        it { should_not allow_value(31).for(:red_below) }
      end

      context "stanine" do
        context "with stanines" do
          let(:stanine_values) { [10,20,30,40,50,60,70,80] }
          subject { build(:evaluation, value_type: :numeric, max_result: 90, stanine_values: stanine_values)}

          # 8 stanine limits
          1.upto(8).each do |i|
            it { should_not allow_value(nil).for(:"stanine#{i}") }
            it { should_not allow_value(-1).for(:"stanine#{i}") }
            it { should_not allow_value(stanine_values[i - 2] - 1).for(:"stanine#{i}") }   if i > 1
            it { should_not allow_value(stanine_values[i]     + 1).for(:"stanine#{i}") }   if i < 8
          end
        end

        context "without stanines" do
          subject { build(:evaluation, value_type: :numeric, max_result: 90, stanine_values: Array.new(8) )}
          it { should be_valid }
        end
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

      context "grade and color ordering" do
        subject { build(:grade_evaluation, color_for_grades: [2] * 6) } # All colors are yellow

        # All values have to be >= than the previous value
        it { should_not allow_value(1).for(:color_for_grade_e) }
        it { should_not allow_value(1).for(:color_for_grade_d) }
        it { should_not allow_value(1).for(:color_for_grade_c) }
        it { should_not allow_value(1).for(:color_for_grade_b) }
        it { should_not allow_value(1).for(:color_for_grade_a) }

        # All values have to be <= than the next value
        it { should_not allow_value(3).for(:color_for_grade_f) }
        it { should_not allow_value(3).for(:color_for_grade_e) }
        it { should_not allow_value(3).for(:color_for_grade_d) }
        it { should_not allow_value(3).for(:color_for_grade_c) }
        it { should_not allow_value(3).for(:color_for_grade_b) }
      end

      context "grade and stanine ordering" do
        subject { build(:grade_evaluation, stanine_for_grades: [5] * 6) } # Stanine 5 for all

        # All values have to be >= than the previous value
        it { should_not allow_value(4).for(:stanine_for_grade_e) }
        it { should_not allow_value(4).for(:stanine_for_grade_d) }
        it { should_not allow_value(4).for(:stanine_for_grade_c) }
        it { should_not allow_value(4).for(:stanine_for_grade_b) }
        it { should_not allow_value(4).for(:stanine_for_grade_a) }

        # All values have to be <= than the next value
        it { should_not allow_value(6).for(:stanine_for_grade_f) }
        it { should_not allow_value(6).for(:stanine_for_grade_e) }
        it { should_not allow_value(6).for(:stanine_for_grade_d) }
        it { should_not allow_value(6).for(:stanine_for_grade_c) }
        it { should_not allow_value(6).for(:stanine_for_grade_b) }
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

  describe ".convert_percentages" do
    subject { create(:evaluation, max_result: 50, red_below: "40%", green_above: "60%") }
    its(:red_below)   { should == 20 }
    its(:green_above) { should == 30 }
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
    context "for boolean value types" do
      subject      { create(:boolean_evaluation, colors: nil, color_for_true: :red, color_for_false: :green) }
      its(:colors) { should include("1" => "red") }
      its(:colors) { should include("0" => "green") }
    end
    context "for grade value types" do
      subject      { create(
        :grade_evaluation,
        colors:             nil,
        stanines:           nil,
        color_for_grades:   [ 1, 1, 2, 2, 3, 3 ],
        stanine_for_grades: [ 2, 3, 5, 6, 7, 9 ]
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
      let(:evaluation) { create(:numeric_evaluation, red_below: 10, green_above: 20, max_result: 30) }

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
        let(:evaluation) { create(:numeric_evaluation, red_below: 0, green_above: 30, max_result: 30) }

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
      let(:evaluation) { create(:grade_evaluation, color_for_grades: [1, 1, 2, 2, 3, 3]) }
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
      let(:stanine_values) { [10, 20, 30, 40, 50, 60, 70, 80] }
      let(:evaluation) { create(:evaluation, max_result: 90, stanine_values: stanine_values) }

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
        let(:stanine_values) { [10, 20, 30, 40, 40, 40, 70, 80]}
        context "giving largest stanine" do
          let(:value) { 40 }
          it          { should == 6 }
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
        let(:stanine_values) { nil }
        let(:value)          { 123 }
        it                   { should be_nil }
      end
    end

    context "for grade value types" do
      let (:evaluation) { create(:grade_evaluation, stanine_for_grades: [2, 2, 3, 5, 7, 9]) }
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

  context "color range methods" do
    let(:max_result)  { 66 }
    let(:red_below)   { 22 }
    let(:green_above) { 44 }
    subject           { create(:evaluation, max_result: max_result, red_below: red_below, green_above: green_above) }


    its(:red_range)    { should == ( 0..21) }
    its(:yellow_range) { should == (22..44) }
    its(:green_range)  { should == (45..66) }

    context "with red edge" do
      let(:red_below) { 1 }
      its(:red_range) { should == 0 }
    end
    context "with no red range" do
      let(:red_below) { 0 }
      its(:red_range) { should be_blank }
    end

    context "with yellow edge" do
      let(:red_below)    { 33 }
      let(:green_above)  { 33 }
      its(:yellow_range) { should == 33 }
    end

    context "with green edge" do
      let(:green_above) { 65 }
      its(:green_range) { should == 66 }
    end
    context "with no green range" do
      let(:green_above) { 66 }
      its(:green_range) { should be_blank }
    end
  end

  describe ".stanines?" do
    it "returns true if all stanine values are set" do
      create(:evaluation, stanine_values: Array.new(8, 1)).stanines?.should be_true
    end
    it "returns false if no stanine values are set" do
      create(:evaluation, stanine_values: Array.new(8)).stanines?.should be_false
    end
  end

  describe ".stanine_limits" do
    let(:stanine_values) { [ 10, 20, 30, 40, 50, 60, 70, 80 ] }
    subject              { create(:evaluation, max_result: 90, stanine_values: stanine_values )}
    its(:stanine_limits) { should == stanine_values}
  end

  describe ".stanine_ranges" do
    let(:stanine_values) { [ 10, 20, 30, 40, 50, 60, 70, 80 ] }
    subject              { create(:evaluation, max_result: 90, stanine_values: stanine_values).stanine_ranges }

    it { should include(1 =>  0..10) }
    it { should include(2 => 11..20) }
    it { should include(3 => 21..30) }
    it { should include(4 => 31..40) }
    it { should include(5 => 41..50) }
    it { should include(6 => 51..60) }
    it { should include(7 => 61..70) }
    it { should include(8 => 71..80) }
    it { should include(9 => 81..90) }

    context "with overlapping stanines" do
      let(:stanine_values) { [ 10, 20, 30, 40, 40, 40, 70, 80 ] }

      it { should include(4 => 31..40) }
      it { should include(5 => 40) }
      it { should include(6 => 40) }
      it { should include(7 => 41..70) }
    end

    context "with edge-to-edge stanines" do
      let(:stanine_values) { [ 10, 11, 12, 13, 14, 15, 16, 17 ] }

      it { should include(1 =>  0..10) }
      it { should include(2 => 11) }
      it { should include(3 => 12) }
      it { should include(4 => 13) }
      it { should include(5 => 14) }
      it { should include(6 => 15) }
      it { should include(7 => 16) }
      it { should include(8 => 17) }
      it { should include(9 => 18..90) }
    end

    context "without stanines" do
      let(:stanine_values) { nil }
      it { should be_blank }
    end
  end

  describe ".result_distribution" do
    let(:target)               { :all }
    let(:suite)                { create(:suite) }
    let!(:male_participants)   { create_list(:male_participant,   1, suite: suite) }
    let!(:female_participants) { create_list(:female_participant, 4, suite: suite) }
    let(:participants)         { male_participants + female_participants }
    let(:evaluation)           { create(:suite_evaluation, suite: suite, max_result: 10, red_below: 4, green_above: 7, target: target) }

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
    end
  end

  describe ".stanine_distribution" do
    subject(:evaluation) { create(:evaluation,
      max_result: 8,
      red_below: 3,
      green_above: 5,
      stanine_values: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
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
    its(:max_result)    { should == template.max_result }
    its(:red_below)     { should == template.red_below }
    its(:green_above)   { should == template.green_above }
    its(:category_list) { should == template.category_list }
    its(:target)        { should == template.target }
    its(:type)          { should == template.type }

    1.upto(8).each do |i|
      its(:"stanine#{i}") { should == template.send(:"stanine#{i}") }
    end

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

  describe "#where_suite_manager" do
    let(:user)                     { create(:superuser) }
    let(:allowed_suite)            { create(:suite) }
    let(:not_allowed_suite)        { create(:suite) }
    let!(:allowed_evaluations)     { create_list(:suite_evaluation, 3, suite: allowed_suite) }
    let!(:not_allowed_evaluations) { create_list(:suite_evaluation, 3, suite: not_allowed_suite) }

    before(:each) do
      user.add_role :suite_manager, allowed_suite
    end

    subject { Evaluation.where_suite_manager(user).all }

    it { should have(3).items }
    it { should match_array(allowed_evaluations) }
  end

  describe "#with_stanines" do
    let!(:without_stanines)         { create(:suite_evaluation, stanine_values: nil, stanines: nil) }
    let!(:with_field_stanines)      { create(:suite_evaluation, stanine_values: [7, 12, 17, 22, 27, 32, 37, 42], stanines: nil) }
    let!(:with_serialized_stanines) { create(:grade_evaluation, stanine_values: nil, stanine_for_grades: [ 1, 3, 4, 5, 6, 9 ]) }

    subject { Evaluation.with_stanines.all }

    it { should have(2).items }
    it { should match_array([with_field_stanines, with_serialized_stanines]) }
  end
end
