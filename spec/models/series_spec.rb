require 'spec_helper'

describe Series do
  context "factories" do
    context "default" do
      subject { build(:series) }
      it      { should be_valid }
    end
    context "invalid" do
      subject { build(:invalid_series) }
      it      { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:suite) }
    it { should allow_mass_assignment_of(:suite_id) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:suite_id) }
  end
end
