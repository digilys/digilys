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
    context "complete suite" do
      # A complete suite evaluation should have all possible data set. This factory
      # is used to test regression when building objects from templates.
      #
      # The specs here use a blacklist for elements that should be excluded when
      # checking for associations. Thus, if a new attribute or association is
      # added to the model, it will automatically break this test, ensuring
      # that a decision is made whether the new attribute or association should be
      # included when creating an object from a template.
      subject { create(:complete_suite_evaluation) }
      it      { should be_a_complete_suite_evaluation }
    end
    context "template" do
      subject { build(:evaluation_template) }
      it { should be_valid }
    end
    context "complete template" do
      # A complete template should have all possible data set. This factory
      # is used to test regression when building objects from templates.
      #
      # The specs here use a blacklist for elements that should be excluded when
      # checking for associations. Thus, if a new attribute or association is
      # added to the model, it will automatically break this test, ensuring
      # that a decision is made whether the new attribute or association should be
      # included when creating an object from a template.
      subject { create(:complete_evaluation_template) }
      it      { should be_a_complete_evaluation_template }
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
    it { should allow_mass_assignment_of(:instance) }
    it { should allow_mass_assignment_of(:instance_id) }
    it { should allow_mass_assignment_of(:suite) }
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

    it { should     allow_mass_assignment_of(:series)}
    it { should     allow_mass_assignment_of(:series_id)}
    it { should_not allow_mass_assignment_of(:is_series_current)}

    it { should_not allow_mass_assignment_of(:imported) }
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
        # it { should     validate_presence_of(:suite) }
        it { should     validate_presence_of(:date) }
        it { should     allow_value("2013-04-29").for(:date) }
        it { should_not allow_value("201304-29").for(:date) }
        it { should_not validate_presence_of(:instance) }
        it { should     allow_value(build(:series)).for(:series) }
        it { should     allow_value(nil).for(:series) }

        context "and with suite template" do
          subject { build(:suite_evaluation, suite: create(:suite, is_template: true)) }
          it { should_not validate_presence_of(:date) }
          # it { should_not allow_value("2013-04-29").for(:date) }
          # it { should_not allow_value("201304-29").for(:date) }
        end
      end
      context "template" do
        subject { build(:evaluation_template) }
        it { should_not validate_presence_of(:suite) }
        it { should_not allow_value(create(:suite)).for(:suite) }
        it { should_not validate_presence_of(:suite) }
        # it { should_not allow_value("2013-04-29").for(:date) }
        it { should     validate_presence_of(:instance) }
        # it { should_not allow_value(build(:series)).for(:series) }
      end
      context "generic" do
        subject { build(:generic_evaluation) }
        it { should_not validate_presence_of(:suite) }
        it { should_not allow_value(create(:suite)).for(:suite) }
        it { should_not validate_presence_of(:suite) }
        # it { should_not allow_value("2013-04-29").for(:date) }
        it { should     validate_presence_of(:instance) }
        # it { should_not allow_value(build(:series)).for(:series) }
      end
    end
  end
  context "associations" do
    let(:suite)       { create(:suite) }

    it "adds the evaluation to the suite's color table" do
      evaluation = create(:suite_evaluation, suite: suite)
      expect(suite.color_table.evaluations(true)).to include(evaluation)
    end
    it "does not add multiple entries for the evaluation to the suite's color table" do
      evaluation = create(:suite_evaluation, suite: suite)
      expect(suite.color_table.evaluations(true).length).to eq 1

      evaluation.name = "#{evaluation.name} updated"
      evaluation.save
      expect(suite.color_table.evaluations(true).length).to eq 1
    end
  end
  context "versioning", versioning: true do
    it { should be_versioned }
    it "stores the new suite id as metadata" do
      evaluation = create(:suite_evaluation)
      evaluation.suite = create(:suite)
      evaluation.save
      expect(evaluation.versions.last.suite_id).to eq evaluation.suite_id
    end
  end

  context "position" do
    let!(:suite)           { create(:suite) }
    let!(:evaluation_1)    { create(:suite_evaluation, suite: suite, position: 1) }
    let!(:evaluation_2)    { create(:suite_evaluation, suite: suite, position: 2) }

    it "moves higher" do
      evaluation_2.move_higher
      expect(evaluation_2.reload.position).to eq 1
      expect(evaluation_1.reload.position).to eq 2
    end
    it "moves to top" do
      evaluation_2.move_to_top
      expect(evaluation_2.reload.position).to eq 1
      expect(evaluation_1.reload.position).to eq 2
    end
    it "moves lower" do
      evaluation_1.move_lower
      expect(evaluation_2.reload.position).to eq 1
      expect(evaluation_1.reload.position).to eq 2
    end
    it "moves to bottom" do
      evaluation_1.move_to_bottom
      expect(evaluation_2.reload.position).to eq 1
      expect(evaluation_1.reload.position).to eq 2
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
      expect(evaluation.valid?).to be_true
      expect(evaluation.evaluation_participant_ids).to match_array(participants.collect(&:id))
    end

    it "clears evaluation_participants if students and groups are cleared" do
      evaluation = create(:suite_evaluation, suite: suite, students_and_groups: "[],,s-#{students.third.id},g-#{group.id}")
      evaluation.students_and_groups = nil
      expect(evaluation.valid?).to be_true
      expect(evaluation.evaluation_participants).to be_blank
    end

    it "does not touch evaluation_participants if the students and groups have not been explicitly cleared" do
      evaluation = create(:suite_evaluation, suite: suite, students_and_groups: "[],,s-#{students.third.id},g-#{group.id}")
      evaluation = Evaluation.find(evaluation.id)
      expect(evaluation.valid?).to be_true
      expect(evaluation.evaluation_participant_ids).not_to be_blank
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

      it "does not change the identity of the persisted object if no changes have occurred" do
        evaluation = build(:boolean_evaluation, value_aliases: Evaluation::BOOLEAN_ALIASES.clone)
        evaluation.send(:set_aliases_from_value_type)
        expect(evaluation.value_aliases).to eq Evaluation::BOOLEAN_ALIASES
        expect(evaluation.value_aliases).not_to be Evaluation::BOOLEAN_ALIASES
      end
    end
    context "for grade value type" do
      subject { create(:grade_evaluation) }
      its(:value_aliases) { should == Evaluation::GRADE_ALIASES }

      it "does not change the identity of the persisted object if no changes have occurred" do
        evaluation = build(:grade_evaluation, value_aliases: Evaluation::GRADE_ALIASES.clone)
        evaluation.send(:set_aliases_from_value_type)
        expect(evaluation.value_aliases).to eq Evaluation::GRADE_ALIASES
        expect(evaluation.value_aliases).not_to be Evaluation::GRADE_ALIASES
      end
    end
  end

  describe ".persist_colors_and_stanines" do
    let(:colors)   { nil }
    let(:stanines) { nil }
    context "for boolean value types" do
      subject(:evaluation) { create(:boolean_evaluation,
        colors: colors,
        color_for_true: :red,
        color_for_false: :green
      ) }

      it "correctly maps the colors" do
        expect(evaluation.colors).to include("1" => "red")
        expect(evaluation.colors).to include("0" => "green")
      end

      it "does not change the identity of the object if no changes have occurred" do
        old = evaluation.colors

        evaluation.color_for_true  = :red
        evaluation.color_for_false = :green
        evaluation.send(:persist_colors_and_stanines)
        expect(evaluation.colors).to be old
      end

      context "with explicitly set colors" do
        let(:colors) { { explicit: 1 } }
        its(:colors) { should == { "explicit" => 1 } }
      end
    end
    context "for grade value types" do
      subject(:evaluation) { create(
        :grade_evaluation,
        colors:          colors,
        stanines:        stanines,
        _grade_colors:   [ 1, 1, 2, 2, 3, 3 ],
        _grade_stanines: [ 2, 3, 5, 6, 7, 9 ]
      ) }
      it "correctly maps the grade colors and stanines" do
        expect(evaluation.colors).to   include("0" => 1)
        expect(evaluation.colors).to   include("1" => 1)
        expect(evaluation.colors).to   include("2" => 2)
        expect(evaluation.colors).to   include("3" => 2)
        expect(evaluation.colors).to   include("4" => 3)
        expect(evaluation.colors).to   include("5" => 3)

        expect(evaluation.stanines).to include("0" => 2)
        expect(evaluation.stanines).to include("1" => 3)
        expect(evaluation.stanines).to include("2" => 5)
        expect(evaluation.stanines).to include("3" => 6)
        expect(evaluation.stanines).to include("4" => 7)
        expect(evaluation.stanines).to include("5" => 9)
      end

      it "does not change the identity of the object if no changes have occurred" do
        old_colors = evaluation.colors
        old_stanines = evaluation.stanines

        evaluation.color_for_grade_a = 3
        evaluation.color_for_grade_b = 3
        evaluation.color_for_grade_c = 2
        evaluation.color_for_grade_d = 2
        evaluation.color_for_grade_e = 1
        evaluation.color_for_grade_f = 1

        evaluation.stanine_for_grade_a = 9
        evaluation.stanine_for_grade_b = 7
        evaluation.stanine_for_grade_c = 6
        evaluation.stanine_for_grade_d = 5
        evaluation.stanine_for_grade_e = 3
        evaluation.stanine_for_grade_f = 2

        evaluation.send(:persist_colors_and_stanines)

        expect(evaluation.colors).to be old_colors
        expect(evaluation.stanines).to be old_stanines
      end

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
      subject(:evaluation) { create(:numeric_evaluation,
        colors:     colors,
        stanines:   stanines,
        _yellow:    _yellow,
        max_result: 30,
        _stanines:  _stanines
      ) }

      it "correctly maps the colors and stanines" do
        expect(evaluation.colors).to   include("red"    => { "min" => 0,  "max" => 9 })
        expect(evaluation.colors).to   include("yellow" => { "min" => 10, "max" => 20 })
        expect(evaluation.colors).to   include("green"  => { "min" => 21, "max" => 30 })

        expect(evaluation.stanines).to include("1"      => { "min" => 0,  "max" => 3 })
        expect(evaluation.stanines).to include("2"      => { "min" => 4,  "max" => 6 })
        expect(evaluation.stanines).to include("3"      => { "min" => 7,  "max" => 7 })
        expect(evaluation.stanines).to include("4"      => { "min" => 8,  "max" => 12 })
        expect(evaluation.stanines).to include("5"      => { "min" => 13, "max" => 15 })
        expect(evaluation.stanines).to include("6"      => { "min" => 16, "max" => 18 })
        expect(evaluation.stanines).to include("7"      => { "min" => 19, "max" => 21 })
        expect(evaluation.stanines).to include("8"      => { "min" => 22, "max" => 24 })
        expect(evaluation.stanines).to include("9"      => { "min" => 25, "max" => 30 })
      end

      context "with only a yellow range" do
        let(:_yellow) { 0..30 }
        it "correctly maps the colors" do
          expect(evaluation.colors).to     include("yellow" => { "min" => 0, "max" => 30 })
          expect(evaluation.colors).not_to have_key("red")
          expect(evaluation.colors).not_to have_key("green")
        end
      end
      context "with overlapping stanines" do
        let(:_stanines) { [ 0..3, 4..6, 7..9, 9..9, 9..9, 10..18, 19..21, 22..30 ] }
        it "correctly maps the stanines" do
          expect(evaluation.stanines).to include("1" => { "min" => 0,  "max" => 3 })
          expect(evaluation.stanines).to include("2" => { "min" => 4,  "max" => 6 })
          expect(evaluation.stanines).to include("3" => { "min" => 7,  "max" => 9 })
          expect(evaluation.stanines).to include("4" => { "min" => 9,  "max" => 9 })
          expect(evaluation.stanines).to include("5" => { "min" => 9,  "max" => 9 })
          expect(evaluation.stanines).to include("6" => { "min" => 10, "max" => 18 })
          expect(evaluation.stanines).to include("7" => { "min" => 19, "max" => 21 })
          expect(evaluation.stanines).to include("8" => { "min" => 22, "max" => 30 })
        end
      end

      it "does not change the identity of the object if no changes have occurred" do
        old_colors = evaluation.colors
        old_stanines = evaluation.stanines

        evaluation.red_min    = 0
        evaluation.red_max    = 9
        evaluation.yellow_min = 10
        evaluation.yellow_max = 20
        evaluation.green_min  = 21
        evaluation.green_max  = 30

        evaluation.stanine1_min = 0
        evaluation.stanine1_max = 3
        evaluation.stanine2_min = 4
        evaluation.stanine2_max = 6
        evaluation.stanine3_min = 7
        evaluation.stanine3_max = 7
        evaluation.stanine4_min = 8
        evaluation.stanine4_max = 12
        evaluation.stanine5_min = 13
        evaluation.stanine5_max = 15
        evaluation.stanine6_min = 16
        evaluation.stanine6_max = 18
        evaluation.stanine7_min = 19
        evaluation.stanine7_max = 21
        evaluation.stanine8_min = 22
        evaluation.stanine8_max = 24
        evaluation.stanine9_min = 25
        evaluation.stanine9_max = 30

        evaluation.send(:persist_colors_and_stanines)

        expect(evaluation.colors).to be old_colors
        expect(evaluation.stanines).to be old_stanines
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

  describe ".overdue?" do
    it "is true when the evaluation is not completed and the date has passed" do
      evaluation = build(:suite_evaluation, date: Date.yesterday, status: :partial)
      expect(evaluation.overdue?).to be_true
    end
    it "is false when the evaluation is completed and the date has passed" do
      evaluation = build(:suite_evaluation, date: Date.yesterday, status: :complete)
      expect(evaluation.overdue?).to be_false
    end
    it "is false when the evaluation is not completed and the date has not passed" do
      evaluation = build(:suite_evaluation, date: Date.today, status: :partial)
      expect(evaluation.overdue?).to be_false
    end
  end
  describe ".completed?" do
    it "matches the status" do
      expect(build(:suite_evaluation, status: :complete)).to    be_completed
      expect(build(:suite_evaluation, status: :partial)).not_to be_completed
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
      expect(evaluation.result_for(student).value).to eq 20
    end
    it "returns nil when the result cannot be found" do
      expect(evaluation.result_for(create(:student))).to be_nil
    end
  end

  describe ".stanines?" do
    it "returns true if there are any stanine values set" do
      expect(create(:evaluation, _stanines: Array.new(9, 1..1)).stanines?).to be_true
    end
    it "returns false if no stanine values are set" do
      expect(create(:evaluation, _stanines: Array.new(9)).stanines?).to be_false
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

  describe ".participants_without_result" do
    let(:suite)                { create(:suite) }
    let!(:male_participants)   { create_list(:male_participant,   2, suite: suite) }
    let!(:female_participants) { create_list(:female_participant, 2, suite: suite) }
    let(:participants)         { male_participants + female_participants }
    let(:evaluation)           { create(:suite_evaluation, suite: suite, max_result: 10, _yellow: 4..7) }

    before(:each) do
      create(:result, student: male_participants.first.student,   evaluation: evaluation, value: 1)
      create(:result, student: female_participants.first.student, evaluation: evaluation, value: 1)
    end

    subject { evaluation.participants_without_result }

    it      { should match_array([ male_participants.second, female_participants.second ])}
  end

  describe ".students_and_groups_select2_data" do
    let(:suite)        { create(:suite) }
    let(:participants) { create_list(:participant, 3, suite: suite) }
    let(:evaluation)   { create(:suite_evaluation, suite: suite) }

    before(:each) do
      evaluation.evaluation_participants = participants
    end

    subject(:objects) { evaluation.students_and_groups_select2_data }

    it "returns select2 entries for all participants, with escaped ids" do
      expect(objects).to have(3).items
      expect(objects).to include({ id: "s-#{participants.first.student_id}",  text: participants.first.student.name })
      expect(objects).to include({ id: "s-#{participants.second.student_id}", text: participants.second.student.name })
      expect(objects).to include({ id: "s-#{participants.third.student_id}",  text: participants.third.student.name })
    end
  end

  describe ".users_select2_data" do
    let(:users)       { create_list(:user, 2) }
    let(:evaluation)  { create(:suite_evaluation, users: users) }
    subject(:objects) { evaluation.users_select2_data }

    it "returns select2 entries for all users, with the text containing name and email" do
      expect(objects).to have(2).items
      expect(objects).to include(id: users.first.id,  text: "#{users.first.name}, #{users.first.email}")
      expect(objects).to include(id: users.second.id, text: "#{users.second.name}, #{users.second.email}")
    end
  end

  describe ".result_distribution" do
    let(:target)               { :all }
    let(:suite)                { create(:suite) }
    let!(:male_participants)   { create_list(:male_participant,   1, suite: suite) }
    let!(:female_participants) { create_list(:female_participant, 4, suite: suite) }
    let(:participants)         { male_participants + female_participants }
    let(:evaluation)           { create(:suite_evaluation, suite: suite, max_result: 10, _yellow: 4..7, target: target) }

    def create_result(participant_index, value)
      create(:result,
        student: participants[participant_index].student,
        evaluation: evaluation,
        value: value,
        absent: value.nil?
      )
    end

    it "returns percentages for all types" do
      create_result(0, 1) # red
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow
      create_result(3, 8) # green

      result = evaluation.result_distribution

      expect(result).to include(not_reported: 20.0)
      expect(result).to include(red:          20.0)
      expect(result).to include(yellow:       40.0)
      expect(result).to include(green:        20.0)
      expect(result).to include(absent:       0)
    end

    it "returns zero for missing colors" do
      create_result(0, 9) # green
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow
      create_result(3, 8) # green

      result = evaluation.result_distribution

      expect(result).to include(not_reported: 20.0)
      expect(result).to include(red:          0)
      expect(result).to include(yellow:       40.0)
      expect(result).to include(green:        40.0)
      expect(result).to include(absent:       0)
    end

    context "without results" do
      subject { create(:evaluation).result_distribution }
      it      { should be_blank }
    end

    context "limited by gender" do
      let(:target) { :female }

      def create_result(participant_index, value)
        create(:result,
          student: female_participants[participant_index].student,
          evaluation: evaluation,
          value: value
        )
      end

      it "returns the correct percentages based on the gender" do
        create_result(0, 1) # red
        create_result(1, 5) # yellow
        create_result(2, 8) # green
        create_result(3, 9) # green

        result = evaluation.result_distribution

        expect(result).to include(not_reported: 0)
        expect(result).to include(red:          25.0)
        expect(result).to include(yellow:       25.0)
        expect(result).to include(green:        50.0)
        expect(result).to include(absent:       0)
      end
    end

    it "handles absent results" do
      create_result(0, nil) # absent
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow
      create_result(3, 8) # green

      result = evaluation.result_distribution

      expect(result).to include(not_reported: 20.0)
      expect(result).to include(red:          0)
      expect(result).to include(yellow:       40.0)
      expect(result).to include(green:        20.0)
      expect(result).to include(absent:       20.0)
    end

    it "handles results from students that are not participants" do
      create_result(0, 1) # red
      create_result(1, 5) # yellow
      create_result(2, 8) # green
      create_result(3, nil) # absent
      # participants[4].student is not reported
      create(:result, evaluation: evaluation, value: 1) # non-participant, red
      create(:result, evaluation: evaluation, value: 1) # non-participant, red
      create(:result, evaluation: evaluation, value: 1) # non-participant, red
      create(:result, evaluation: evaluation, value: 5) # non-participant, yellow
      create(:result, evaluation: evaluation, value: 8) # non-participant, green

      result = evaluation.result_distribution

      expect(result).to include(not_reported: 10.0)
      expect(result).to include(red:          40.0)
      expect(result).to include(yellow:       20.0)
      expect(result).to include(green:        20.0)
      expect(result).to include(absent:       10.0)
    end
  end

  describe ".stanine_distribution" do
    let(:evaluation) { create(:evaluation,
      max_result: 8,
      _yellow: 3..5,
      _stanines: [ 0..0, 1..1, 2..2, 3..3, 4..4, 5..5, 6..6, 7..7, 8..8 ]
    ) }

    it "returns a correct stanine distribution" do
      # No 5, two 4:s (stanine)
      [0, 1, 2, 3, 3, 5, 6, 7, 8].each do |value|
        create(:result, evaluation: evaluation, value: value)
      end

      result = evaluation.stanine_distribution

      expect(result).to have(8).items
      expect(result).to include(1 => 1)
      expect(result).to include(2 => 1)
      expect(result).to include(3 => 1)
      expect(result).to include(4 => 2)
      expect(result).to include(6 => 1)
      expect(result).to include(7 => 1)
      expect(result).to include(8 => 1)
      expect(result).to include(9 => 1)
      expect(result).not_to have_key(5)
    end
  end

  describe ".alias_for" do
    let(:aliases)    { { 1 => "foo", 2 => "bar" } }
    let(:evaluation) { create(:evaluation, value_aliases: aliases) }

    it "converts a raw value to its alias" do
      expect(evaluation.alias_for(1)).to eq "foo"
    end
    it "returns the raw value if there is no alias" do
      expect(evaluation.alias_for(3)).to eq 3
    end
    context "without aliases" do
      let(:aliases) { nil }
      it "returns the raw value" do
        expect(evaluation.alias_for(1)).to eq 1
      end
    end
  end

  describe ".update_status!" do
    let!(:suite)           { create(:suite) }
    let(:num_participants) { 0 }
    let(:num_results)      { 0 }
    let!(:evaluation)      { create(:suite_evaluation, suite: suite) }
    let!(:table_state)       { create(:table_state, base: suite.color_table, data: { "hiddenColumns" => ["evaluation-x"] }) }

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
        it "should add itself to hidden columns for each color table state" do
          expect(table_state.reload.data["hiddenColumns"]).to include("evaluation-#{evaluation.id}")
        end
      end
      context "and partial results" do
        let(:num_results) { 2 }
        its(:status)      { should == "partial" }
        it "should add itself to hidden columns for each color table state" do
          expect(table_state.reload.data["hiddenColumns"]).to include("evaluation-#{evaluation.id}")
        end
      end
    end

    context "with results" do
      let(:num_participants) { 3 }
      let(:num_results) { 1 }
      its(:status)           { should == "partial" }

      context "after removing results" do
        before(:each) do
          evaluation.results.each do |r|
            r.destroy
          end
        end
        it "should still be in hidden columns for table states" do
          expect(table_state.reload.data["hiddenColumns"]).to include("evaluation-#{evaluation.id}")
        end
      end
    end
  end

  describe ".update_series_current!" do
    let(:series)       { create(:series) }
    let!(:evaluation1) { create(:suite_evaluation, series: series, date: Date.today,     status: :empty) }
    let!(:evaluation2) { create(:suite_evaluation, series: series, date: Date.yesterday, status: :partial, is_series_current: true) }
    let!(:evaluation3) { create(:suite_evaluation, date: Date.tomorrow, status: :complete) }

    it "changes the series current when the status of an evaluation changes to not empty" do
      evaluation1.status = :partial
      evaluation1.save

      expect(evaluation1.reload.is_series_current).to be_true
      expect(evaluation2.reload.is_series_current).to be_false
    end
    it "changes the series current when adding a suite to a series" do
      evaluation3.series = series
      evaluation3.save
      expect(evaluation3.reload.is_series_current).to be_true
      expect(evaluation2.reload.is_series_current).to be_false
    end
  end

  describe ".create_series_from_name" do
    it "creates a new series if series_id is a string" do
      expect(Series.exists?).to be_false
      evaluation = build(:suite_evaluation, series_id: "My series")
      expect(evaluation.save).to         be_true
      expect(evaluation.series.name).to  eq "My series"
      expect(evaluation.series.suite).to eq evaluation.suite
    end
    it "associates the event with an existing series if a series with the name exists" do
      series = create(:series, name: "my series")
      evaluation = build(:suite_evaluation, suite: series.suite, series_id: "MY SERIES")
      expect(evaluation.save).to   be_true
      expect(evaluation.series).to eq series
    end
    it "does not create a series when no name is given" do
      evaluation = build(:suite_evaluation, series_id: "")
      expect(evaluation.save).to   be_true
      expect(evaluation.series).to be_nil
    end
  end

  describe ".destroy_empty_series!" do
    let(:series) { create(:series) }
    let(:suite)  { series.suite }

    it "destroys a series after disassociation if the series has no other evaluations" do
      evaluation = create(:suite_evaluation, suite: suite, series: series)
      evaluation.series = nil
      evaluation.save!

      expect(Series.where(id: series.id).exists?).to be_false
    end
    it "do not destroys a series after evaluation destroy if the series has no other evaluations" do
      evaluation = create(:suite_evaluation, suite: suite, series: series)
      evaluation.destroy

      expect(Series.where(id: series.id).exists?).to be_true
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
    its(:series_id)     { should be_nil }

    context "with attrs" do
      subject { Evaluation.new_from_template(template, { suite_id: 1, name: "Overridden" }) }
      its(:suite_id) { should == 1 }
      its(:name)     { should == "Overridden" }
    end
    context "with series" do
      let(:suite)     { create(:suite) }
      let(:series)    { create(:series, suite: suite) }
      let(:template)  { create(:suite_evaluation, series: series, suite: suite) }
      its(:series_id) { should == series.id }
    end
  end

  describe "#in_instance" do
    let(:suite1)       { create(:suite) }
    let(:suite2)       { create(:suite, instance: create(:instance)) }
    let!(:evaluation1) { create(:suite_evaluation, suite: suite1) }
    let!(:evaluation2) { create(:suite_evaluation, suite: suite2) }

    subject { Evaluation.in_instance(suite1.instance_id).all }
    it      { should match_array([ evaluation1 ])}
  end
  describe "#search_in_instance" do
    let(:suite1)       { create(:suite, name: "suite 1") }
    let(:suite2)       { create(:suite, name: "suite 2", instance: create(:instance)) }
    let!(:generic)     { create(:generic_evaluation, name: "evaluation 1", instance: suite1.instance) }
    let!(:evaluation1) { create(:suite_evaluation, suite: suite1, name: "evaluation 1") }
    let!(:evaluation2) { create(:suite_evaluation, suite: suite1, name: "evaluation 2") }
    let!(:evaluation3) { create(:suite_evaluation, suite: suite2, name: "evaluation 1") }

    it "searches in an instance" do
      result = Evaluation.search_in_instance(suite1.instance_id, name_cont: "1")
      expect(result).to match_array([ evaluation1, generic ])
    end
    it "handles when the search automatically joins the suite table" do
      result = Evaluation.search_in_instance(suite1.instance_id, suite_name_cont: "1")
      expect(result).to match_array([ evaluation1, evaluation2 ])
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

    it { should match_array(with_partial_results + without_results) }
  end
  describe "#upcoming" do
    let!(:passed)   { create_list(:suite_evaluation, 3, date: Date.yesterday) }
    let!(:upcoming) { create_list(:suite_evaluation, 3, date: Date.today) }
    subject         { Evaluation.upcoming.all }
    it              { should match_array(upcoming) }
  end

  describe "#where_suite_member" do
    let(:user)                     { create(:planner) }
    let(:contributed_suite)        { create(:suite) }
    let(:managed_suite)            { create(:suite) }
    let(:not_allowed_suite)        { create(:suite) }
    let!(:allowed_evaluations)     { create_list(:suite_evaluation, 3, suite: contributed_suite) + create_list(:suite_evaluation, 3, suite: managed_suite) }
    let!(:not_allowed_evaluations) { create_list(:suite_evaluation, 3, suite: not_allowed_suite) }

    before(:each) do
      user.add_role :suite_member,  contributed_suite
      user.add_role :suite_manager, managed_suite
    end

    subject { Evaluation.where_suite_member(user).all }

    it { should match_array(allowed_evaluations) }
  end

  describe "#with_stanines" do
    let!(:without_stanines)      { create(:boolean_evaluation, stanines: nil) }
    let!(:with_numeric_stanines) { create(:numeric_evaluation, _stanines: Array.new(9, 1..1)) }
    let!(:with_grade_stanines)   { create(:grade_evaluation,   _grade_stanines: [ 1, 3, 4, 5, 6, 9 ]) }

    subject { Evaluation.with_stanines.all }

    it { should match_array([with_numeric_stanines, with_grade_stanines]) }
  end

  describe "#without_explicit_users" do
    let!(:user)                   { create(:user) }
    let!(:with_explicit_users)    { create_list(:suite_evaluation, 2) }
    let!(:without_explicit_users) { create_list(:suite_evaluation, 3) }

    before(:each) { with_explicit_users.each { |e| e.users << user } }

    subject { Evaluation.without_explicit_users.all }

    it { should match_array(without_explicit_users) }
  end

  describe "#only_series_currents" do
    it "returns all evaluations that is the current one of a series" do
      series = create(:series)

      current = create :suite_evaluation, series: series,          date: Date.today,     status: :partial
      create           :suite_evaluation, series: series,          date: Date.yesterday, status: :complete
      create           :suite_evaluation, series: series,          date: Date.tomorrow,  status: :empty
      create           :suite_evaluation, series: create(:series), date: Date.today,     status: :empty

      expect(Evaluation.only_series_currents.all).to eq [current]
    end
    it "returns all non-series evaluations" do
      evaluations = [
        create(:suite_evaluation,    status: :empty), # no series
        create(:evaluation_template, status: :empty), # other types
        create(:generic_evaluation,  status: :empty)
      ]
      expect(Evaluation.only_series_currents.all).to match_array(evaluations)
    end
  end

  describe "#missing_generics_for" do
    let(:generics)       { create_list(:generic_evaluation, 2) }
    let(:wrong_type)     { create(:evaluation_template) }
    let(:wrong_instance) { create(:generic_evaluation, instance: create(:instance)) }

    it "returns all generic evaluations which are not associated to the given object" do
      obj = build(:suite, generic_evaluations: [generics.first])
      expect(Evaluation.missing_generics_for(obj)).to eq [generics.second]
    end
    it "handles empty arrays on the object" do
      generics
      obj = build(:suite, generic_evaluations: nil)
      expect(Evaluation.missing_generics_for(obj)).to eq generics
    end
    it "only includes generics from the same instance" do
      wrong_type
      wrong_instance
      obj = build(:suite, generic_evaluations: [generics.first])
      expect(Evaluation.missing_generics_for(obj)).to eq [generics.second]
    end
  end

  describe "#generic_cache_key" do
    subject { Evaluation.generic_cache_key }
    context "with generic evaluations" do
      let(:oldest) { Time.now - 10.minutes }
      let(:newest) { Time.now + 10.minutes }

      before(:each) do
        Timecop.freeze(oldest) do
          create(:generic_evaluation)
        end
        Timecop.freeze(newest) do
          create(:generic_evaluation)
        end
      end

      it { should == newest.utc.to_s(ActiveRecord::Base.cache_timestamp_format) }
    end
    context "without generic evaluations" do
      it { should be_nil }
    end
  end

  describe ".series_name" do
    let(:series) { create(:series) }
    it "returns the series name" do
      expect(build(:suite_evaluation, series: series).series_name).to eq series.name
    end
    it "is nil if there is no series" do
      expect(build(:suite_evaluation).series_name).to be_nil
    end
    it "returns the raw series id if series_id is 0" do
      evaluation = build(:suite_evaluation, series_id: "zomg")
      expect(evaluation.series_id).to eq 0
      expect(evaluation.series_name).to eq "zomg"
    end
  end
end
