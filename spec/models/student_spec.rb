require 'spec_helper'

describe Student do
  context "factory" do
    subject { build(:student) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
  end
end
