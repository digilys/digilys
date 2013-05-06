require 'spec_helper'

describe Participant do
  context "factory" do
    subject { build(:student) }
    it { should be_valid }
  end

  context "validation" do
    it { should validate_presence_of(:student) }
    it { should validate_presence_of(:suite) }
  end

  context ".name" do
    let(:student) { create(:student) }
    subject { create(:participant, student: student).name }
    it { should == student.name }
  end

  context ".group_names" do
    let(:groups)  { create_list(:group, 2)}
    let(:student) { create(:student) }
    before(:each) { student.groups = groups }
    subject { create(:participant, student: student).group_names.split(/\s*,\s*/) } # Split by comma so we can test by comparing arrays
    it { should match_array(groups.collect(&:name)) }
  end
end
