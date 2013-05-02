require 'spec_helper'

describe Group do
  context "factory" do
    subject { build(:group) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:parent_id) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
  end
end
