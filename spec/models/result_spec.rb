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
  end
  context "validation" do
    it { should validate_presence_of(:evaluation) }
    it { should validate_presence_of(:student) }
    it { should validate_numericality_of(:value).only_integer }

    context "of the value" do
      let(:evaluation) { build(:evaluation, max_result: rand(100))}
      subject          { build(:result,     evaluation: evaluation) }
      it { should_not allow_value(-1).for(:value) }
      it { should_not allow_value(evaluation.max_result + 1).for(:value) }
      it { should     allow_value(0).for(:value) }
      it { should     allow_value(evaluation.max_result).for(:value) }
    end
  end

  context ".color" do
    let(:evaluation) { create(:evaluation, max_result: 10, red_below: 4, green_above: 7) }

    it "returns red when the value is strictly below the red limit" do
      create(:result, evaluation: evaluation, value: 3).color.should == :red
    end
    it "returns yellow when the value is between the red and green limits" do
      create(:result, evaluation: evaluation, value: 4).color.should == :yellow
      create(:result, evaluation: evaluation, value: 7).color.should == :yellow
    end
    it "returns green when the value is strictly above the green limit" do
      create(:result, evaluation: evaluation, value: 8).color.should == :green
    end
  end

  context ".stanine" do
    let(:stanine_limits) { [10, 20, 30, 40, 50, 60, 70, 80] }
    let(:evaluation) { create(:evaluation, max_result: 90, stanines: stanine_limits) }

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
      it "correctly gives stanine #{stanine}" do
        create(:result, evaluation: evaluation, value: values.first ).stanine.should == stanine
        create(:result, evaluation: evaluation, value: values.second).stanine.should == stanine
      end
    end

    context "with overlapping stanines" do
      let(:stanine_limits) { [10, 20, 30, 40, 40, 40, 70, 80]}
      it "selects the largest stanine when the value matches several" do
        create(:result, evaluation: evaluation, value: 40).stanine.should == 6
      end
      it "selects the correct stanine below" do
        create(:result, evaluation: evaluation, value: 39).stanine.should == 4
      end
      it "selects the correct stanine above" do
        create(:result, evaluation: evaluation, value: 41).stanine.should == 7
      end
    end

    context "without stanines" do
      let(:stanine_limits) { nil }
      subject { create(:result, evaluation: evaluation, value: 50 ) }
      its(:stanine) { should be_nil }
    end
  end
end
