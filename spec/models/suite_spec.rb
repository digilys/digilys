require 'spec_helper'

describe Suite do
  context "factory" do
    subject { build(:suite) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
  end
end
