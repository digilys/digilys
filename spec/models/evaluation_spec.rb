require 'spec_helper'

describe Evaluation do
  context "factory" do
    subject { build(:evaluation) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:description) }
    it { should allow_mass_assignment_of(:date) }
    it { should allow_mass_assignment_of(:max_result) }
    it { should allow_mass_assignment_of(:red_below) }
    it { should allow_mass_assignment_of(:green_above) }
    it { should allow_mass_assignment_of(:stanine1) }
    it { should allow_mass_assignment_of(:stanine2) }
    it { should allow_mass_assignment_of(:stanine3) }
    it { should allow_mass_assignment_of(:stanine4) }
    it { should allow_mass_assignment_of(:stanine5) }
    it { should allow_mass_assignment_of(:stanine6) }
    it { should allow_mass_assignment_of(:stanine7) }
    it { should allow_mass_assignment_of(:stanine8) }
  end
  context "validation" do
    it { should     validate_presence_of(:name) }
    it { should_not validate_presence_of(:date) }

    it { should validate_numericality_of(:max_result).only_integer }
    it { should validate_numericality_of(:red_below).only_integer }
    it { should validate_numericality_of(:green_above).only_integer }

    it { should validate_numericality_of(:stanine1).only_integer }
    it { should validate_numericality_of(:stanine2).only_integer }
    it { should validate_numericality_of(:stanine3).only_integer }
    it { should validate_numericality_of(:stanine4).only_integer }
    it { should validate_numericality_of(:stanine5).only_integer }
    it { should validate_numericality_of(:stanine6).only_integer }
    it { should validate_numericality_of(:stanine7).only_integer }
    it { should validate_numericality_of(:stanine8).only_integer }

    it { should_not allow_value(-1).for(:max_result) }

    context "limit ranges" do
      subject { build(:evaluation, max_result: 50, red_below: 20, green_above: 30) }
      it { should_not allow_value(-1).for(:red_below) }
      it { should_not allow_value(51).for(:green_above) }
      it { should_not allow_value(19).for(:green_above) }
      it { should_not allow_value(31).for(:red_below) }
    end

    context "stanine" do
      context "with stanines" do
        let(:stanine_limits) { [10,20,30,40,50,60,70,80] }
        subject { build(:evaluation, max_result: 90, stanines: stanine_limits)}

        # 8 stanine limits
        1.upto(8).each do |i|
          it { should_not allow_value(nil).for(:"stanine#{i}") }
          it { should_not allow_value(-1).for(:"stanine#{i}") }
          it { should_not allow_value(stanine_limits[i - 2] - 1).for(:"stanine#{i}") }   if i > 1
          it { should_not allow_value(stanine_limits[i]     + 1).for(:"stanine#{i}") }   if i < 8
        end
      end

      context "without stanines" do
        subject { build(:evaluation, max_result: 90, stanines: Array.new(8) )}
        it { should be_valid }
      end
    end

    context "with regular suite" do
      subject { build(:evaluation, suite: create(:suite, is_template: false)) }
      it { should validate_presence_of(:date) }
      it { should     allow_value("2013-04-29").for(:date) }
      it { should_not allow_value("201304-29").for(:date) }
    end
  end

  context ".convert_percentages" do
    subject { create(:evaluation, max_result: 50, red_below: "40%", green_above: "60%") }
    its(:red_below)   { should == 20 }
    its(:green_above) { should == 30 }
  end

  context ".has_regular_suite?" do
    context "with no suite" do
      subject { build(:evaluation, suite: nil).has_regular_suite? }
      it { should be_false }
    end
    context "with template suite" do
      subject { build(:evaluation, suite: create(:suite, is_template: true)).has_regular_suite? }
      it { should be_false }
    end
    context "with regular suite" do
      subject { build(:evaluation, suite: create(:suite, is_template: false)).has_regular_suite? }
      it { should be_true }
    end
  end

  context ".color_for" do
    let(:evaluation) { create(:evaluation, red_below: 10, green_above: 20, max_result: 30) }
    let(:value)      { nil }
    subject          { evaluation.color_for(value) }

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
  end
  context ".stanine_for" do
    let(:stanine_limits) { [10, 20, 30, 40, 50, 60, 70, 80] }
    let(:evaluation) { create(:evaluation, max_result: 90, stanines: stanine_limits) }
    let(:value)      { nil }
    subject          { evaluation.stanine_for(value) }

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
      let(:stanine_limits) { [10, 20, 30, 40, 40, 40, 70, 80]}
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
      let(:stanine_limits) { nil }
      let(:value)          { 123 }
      it                   { should be_nil }
    end
  end

  context ".result_for" do
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

  context ".stanines?" do
    it "returns true if all stanine values are set" do
      create(:evaluation, stanines: Array.new(8, 1)).stanines?.should be_true
    end
    it "stanines are " do
      create(:evaluation, stanines: Array.new(8)).stanines?.should be_false
    end
  end

  context ".stanines" do
    let(:stanine_limits) { [ 10, 20, 30, 40, 50, 60, 70, 80 ] }
    subject              { create(:evaluation, max_result: 90, stanines: stanine_limits )}
    its(:stanines)       { should == stanine_limits}
  end

  context ".stanine_ranges" do
    let(:stanine_limits) { [ 10, 20, 30, 40, 50, 60, 70, 80 ] }
    subject              { create(:evaluation, max_result: 90, stanines: stanine_limits ).stanine_ranges }

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
      let(:stanine_limits) { [ 10, 20, 30, 40, 40, 40, 70, 80 ] }

      it { should include(4 => 31..40) }
      it { should include(5 => 40) }
      it { should include(6 => 40) }
      it { should include(7 => 41..70) }
    end

    context "with edge-to-edge stanines" do
      let(:stanine_limits) { [ 10, 11, 12, 13, 14, 15, 16, 17 ] }

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
      let(:stanine_limits) { nil }
      it { should be_blank }
    end
  end

  context ".result_distribution" do
    let(:suite)        { create(:suite) }
    let(:participants) { create_list(:participant, 5, suite: suite) }
    let(:evaluation)   { create(:evaluation, suite: suite, max_result: 10, red_below: 4, green_above: 7) }

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

    context "without results" do
      subject { create(:evaluation).result_distribution }
      it      { should be_blank }
    end
  end

  context "#new_from_template" do
    let(:template) { create(:evaluation, category_list: "foo, bar, baz") }
    subject        { Evaluation.new_from_template(template) }

    its(:template_id)   { should == template.id }
    its(:name)          { should == template.name }
    its(:description)   { should == template.description }
    its(:max_result)    { should == template.max_result }
    its(:red_below)     { should == template.red_below }
    its(:green_above)   { should == template.green_above }
    its(:category_list) { should == template.category_list }

    1.upto(8).each do |i|
      its(:"stanine#{i}") { should == template.send(:"stanine#{i}") }
    end

    context "with attrs" do
      subject { Evaluation.new_from_template(template, { suite_id: 1, name: "Overridden" }) }
      its(:suite_id) { should == 1 }
      its(:name)     { should == "Overridden" }
    end
  end

  context "#templates" do
    let!(:templates) { create_list(:evaluation,            3) }
    let!(:regular)   { create_list(:evaluation_with_suite, 3) }
    it "should scope to templates only" do
      Evaluation.templates.all.should match_array(templates)
    end
  end
end
