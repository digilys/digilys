require 'spec_helper'

describe Result do
  context "factory" do
    subject { build(:result) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:evaluation_id) }
    it { should allow_mass_assignment_of(:student_id) }
    it { should allow_mass_assignment_of(:value) }
    it { should allow_mass_assignment_of(:absent) }
  end
  context "validation" do
    it { should validate_presence_of(:evaluation) }
    it { should validate_presence_of(:student) }
    it { should validate_numericality_of(:value).only_integer }

    it { should_not allow_value(nil).for(:value) }

    context "of the value" do
      let(:evaluation) { build(:evaluation, max_result: rand(100))}
      subject          { build(:result,     evaluation: evaluation) }
      it { should_not allow_value(-1).for(:value) }
      it { should_not allow_value(evaluation.max_result + 1).for(:value) }
      it { should     allow_value(0).for(:value) }
      it { should     allow_value(evaluation.max_result).for(:value) }

      context "when absent is true" do
        subject { build(:result, evaluation: evaluation, absent: true) }
        it { should allow_value(nil).for(:value) }
      end
    end
  end

  context "color filter" do
    let(:evaluation) { create(:numeric_evaluation, max_result: 10, _yellow: 4..7) }
    let(:value)      { 5 }
    let(:absent)     { false }
    subject(:result) { create(:result, evaluation: evaluation, value: value, absent: absent) }

    context "with red value" do
      let(:value) { 3 }
      its(:color) { should == :red }
    end
    context "with yellow value, lower edge" do
      let(:value) { 4 }
      its(:color) { should == :yellow }
    end
    context "with yellow value, upper edge" do
      let(:value) { 7 }
      its(:color) { should == :yellow }
    end
    context "with green value" do
      let(:value) { 8 }
      its(:color) { should == :green }
    end

    context "with absent value" do
      let(:absent) { true }
      let(:value)  { nil }
      its(:color)  { should be_nil }
    end

    it "updates the color when the evaluation changes" do
      result.color.should == :yellow
      evaluation.update_attributes(red_max: 6, yellow_min: 7)
      result.reload
      result.color.should == :red
    end
  end

  describe ".stanine" do
    let(:_stanines) { [ 0..10, 11..20, 21..30, 31..40, 41..50, 51..60, 61..70, 71..80, 81..90 ] }
    let(:evaluation)     { create(:evaluation, max_result: 90, _stanines: _stanines) }
    let(:value)          { 35 }
    subject(:result)     { create(:result, evaluation: evaluation, value: value) }

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
        let(:value)   { values.first }
        its(:stanine) { should == stanine }
      end
      context "stanine #{stanine}, upper bound" do
        let(:value)   { values.second }
        its(:stanine) { should == stanine }
      end
    end

    context "with overlapping stanines" do
      let(:_stanines) { [10, 20, 30, 40, 40, 40, 70, 80]}
      let(:_stanines) { [ 0..10, 11..20, 21..30, 31..40, 40..40, 40..40, 41..70, 71..80, 81..90 ] }
      context "when matching several" do
        let(:value)   { 40 }
        its(:stanine) { should == 4 }
      end
      context "when matching above" do
        let(:value)   { 41 }
        its(:stanine) { should == 7 }
      end
    end

    context "without stanines" do
      let(:_stanines) { nil }
      its(:stanine)        { should be_nil }
    end

    it "updates the stanine when the evaluation changes" do
      result.stanine.should == 4
      evaluation.update_attributes(stanine3_max: 38, stanine4_min: 39)
      result.reload
      result.stanine.should == 3
    end
  end

  describe ".display_value" do
    let(:aliases)    { { 1 => "foo", 2 => "bar" } }
    let(:evaluation) { create(:evaluation, value_aliases: aliases) }
    let(:value)      { nil }
    subject          { create(:result, evaluation: evaluation, value: value) }

    context "with a value with an alias" do
      let(:value) { 1 }
      its(:display_value) { should == "foo" }
    end
    context "with a value without an alias" do
      let(:value) { 3 }
      its(:display_value) { should == "3" }
    end
  end

  describe ".update_evaluation_status!" do
    let(:suite) { create(:suite) }
    let(:evaluation) { create(:suite_evaluation, suite: suite) }
    let(:participants) { create_list(:participant, 2, suite: suite) }
    let!(:results) { [ create(:result, evaluation: evaluation, student: participants.first.student) ]  }

    it "updates the suite's evaluations' statuses" do
      evaluation.update_status!
      evaluation.reload
      evaluation.status.should == "partial"
      result = create(:result, evaluation: evaluation, student: participants.second.student)
      evaluation.reload
      evaluation.status.should == "complete"
      result.destroy
      evaluation.reload
      evaluation.status.should == "partial"
    end
  end
end
