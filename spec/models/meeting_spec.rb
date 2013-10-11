require 'spec_helper'

describe Meeting do
  context "factory" do
    subject { build(:meeting) }
    it { should be_valid }

    context "invalid" do
      subject { build(:invalid_meeting) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:date) }
    it { should allow_mass_assignment_of(:agenda) }
    it { should allow_mass_assignment_of(:completed) }
    it { should allow_mass_assignment_of(:notes) }
  end
  context "validation" do
    it { should     validate_presence_of(:suite) }
    it { should     validate_presence_of(:name) }
    it { should_not validate_presence_of(:date) }

    context "with regular suite" do
      subject { build(:meeting, suite: create(:suite, is_template: false)) }
      it { should     validate_presence_of(:date) }
      it { should     allow_value("2013-04-29").for(:date) }
      it { should_not allow_value("201304-29").for(:date) }
    end
  end
  context "associations" do
    let(:suite) { create(:suite) }

    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        participant = create(:meeting, suite: suite)
        updated_at.should < suite.reload.updated_at
      end
    end
  end

  context ".has_regular_suite?" do
    context "with no suite" do
      subject { build(:meeting, suite: nil).has_regular_suite? }
      it { should be_false }
    end
    context "with template suite" do
      subject { build(:meeting, suite: create(:suite, is_template: true)).has_regular_suite? }
      it { should be_false }
    end
    context "with regular suite" do
      subject { build(:meeting, suite: create(:suite, is_template: false)).has_regular_suite? }
      it { should be_true }
    end
  end

  context ".overdue?" do
    it "returns true for past meetings that are not completed" do
      create(:meeting, date: Date.today - 1, completed: false).should     be_overdue
    end
    it "returns false for future meetings" do
      create(:meeting, date: Date.today + 1, completed: false).should_not be_overdue
    end
    it "returns false for past meetings that are completed" do
      create(:meeting, date: Date.today - 1, completed: true ).should_not be_overdue
    end
    it "considers today's date to be a future meeting" do
      create(:meeting, date: Date.today    , completed: false).should_not be_overdue
    end
  end

  describe "#in_instance" do
    let(:suite1)    { create(:suite) }
    let(:suite2)    { create(:suite,   instance: create(:instance)) }
    let!(:meeting1) { create(:meeting, suite:    suite1) }
    let!(:meeting2) { create(:meeting, suite:    suite2) }

    subject { Meeting.in_instance(suite1.instance_id).all }
    it      { should match_array([ meeting1 ])}
  end

  describe "#upcoming" do
    let!(:passed)   { create_list(:meeting, 3, date: Date.yesterday) }
    let!(:upcoming) { create_list(:meeting, 3, date: Date.today) }
    subject         { Meeting.upcoming.all }
    it              { should have(3).items }
    it              { should match_array(upcoming) }
  end

  describe "#where_suite_member" do
    let(:user)                  { create(:superuser) }
    let(:contributed_suite)     { create(:suite) }
    let(:managed_suite)         { create(:suite) }
    let(:not_allowed_suite)     { create(:suite) }
    let!(:allowed_meetings)     { create_list(:meeting, 3, suite: contributed_suite) + create_list(:meeting, 3, suite: managed_suite) }
    let!(:not_allowed_meetings) { create_list(:meeting, 3, suite: not_allowed_suite) }

    before(:each) do
      user.add_role :suite_member,  contributed_suite
      user.add_role :suite_manager, managed_suite
    end

    subject { Meeting.where_suite_member(user).all }

    it { should have(6).items }
    it { should match_array(allowed_meetings) }
  end
end
