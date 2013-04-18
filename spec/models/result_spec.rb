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
end
