require 'spec_helper'

describe Instance do
  context "factories" do
    context "default" do
      subject { build(:instance) }
      it      { should be_valid }
    end
    context "invalid" do
      subject { build(:invalid_instance) }
      it      { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
  end
end
