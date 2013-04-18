require 'spec_helper'

describe Evaluation do
  context "factory" do
    subject { build(:evaluation) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:max_result) }
    it { should allow_mass_assignment_of(:red_below) }
    it { should allow_mass_assignment_of(:green_above) }
  end
  context "validation" do
    it { should validate_presence_of(:suite) }
    it { should validate_presence_of(:name) }

    it { should validate_numericality_of(:max_result).only_integer }
    it { should validate_numericality_of(:red_below).only_integer }
    it { should validate_numericality_of(:green_above).only_integer }

    it { should_not allow_value(-1).for(:max_result) }

    context "limit ranges" do
      subject { build(:evaluation, max_result: 50, red_below: 20, green_above: 30) }
      it { should_not allow_value(-1).for(:red_below) }
      it { should_not allow_value(51).for(:green_above) }
      it { should_not allow_value(19).for(:green_above) }
      it { should_not allow_value(31).for(:red_below) }
    end
  end
end
