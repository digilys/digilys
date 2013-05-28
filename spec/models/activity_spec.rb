require 'spec_helper'

describe Activity do
  context "factory" do
    subject { build(:activity) }
    it      { should be_valid }

    context "for action activity" do
      subject { build(:action_activity) }
      it      { should be_valid }
    end
    context "for inquiry activity" do
      subject { build(:inquiry_activity) }
      it      { should be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:type) }
    it { should allow_mass_assignment_of(:status) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:description) }
    it { should allow_mass_assignment_of(:notes) }
  end
  context "validation" do
    it { should validate_presence_of(:suite) }
    it { should validate_presence_of(:name) }
    it { should ensure_inclusion_of(:type).in_array(%w(action inquiry)) }
    it { should ensure_inclusion_of(:status).in_array(%w(open closed)) }
  end

  describe ".set_suite_from_meeting" do
    let(:suite)        { nil }
    let(:meeting)      { create(:meeting) }
    subject(:activity) { build(:activity, suite: suite, meeting: meeting)}
    before(:each)      { activity.valid? }

    its(:suite) { should == meeting.suite }

    context "with existing suite" do
      let(:suite) { create(:suite) }
      its(:suite) { should == suite }
    end
  end
end
