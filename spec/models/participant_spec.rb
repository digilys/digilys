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
end
