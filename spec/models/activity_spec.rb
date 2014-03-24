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
    context "for invalid activity" do
      subject { build(:invalid_activity) }
      it      { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:type) }
    it { should allow_mass_assignment_of(:status) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:start_date) }
    it { should allow_mass_assignment_of(:end_date) }
    it { should allow_mass_assignment_of(:description) }
    it { should allow_mass_assignment_of(:notes) }
  end
  context "validation" do
    it { should validate_presence_of(:suite) }
    it { should validate_presence_of(:name) }
    it { should ensure_inclusion_of(:type).in_array(%w(action inquiry)) }
    it { should ensure_inclusion_of(:status).in_array(%w(open closed)) }

    it { should     allow_value(nil).for(:start_date) }
    it { should     allow_value("").for(:start_date) }
    it { should_not allow_value("201-06-07").for(:start_date) }
    it { should     allow_value(nil).for(:end_date) }
    it { should     allow_value("").for(:end_date) }
    it { should_not allow_value("201-06-07").for(:end_date) }
  end
  context "associations" do
    let(:suite) { create(:suite) }

    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        participant = create(:activity, suite: suite)
        updated_at.should < suite.reload.updated_at
      end
    end
  end
  context "versioning", versioning: true do
    it { should be_versioned }
    it "stores the new suite id as metadata" do
      activity = create(:activity)
      activity.suite = create(:suite)
      activity.save
      activity.versions.last.suite_id.should == activity.suite_id
    end
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

  context ".overdue?" do
    it "returns true for past activities that are not completed" do
      create(:activity, end_date: Date.today - 1, status: :open).should     be_overdue
    end
    it "returns false for future activities" do
      create(:activity, end_date: Date.today + 1, status: :open).should_not be_overdue
    end
    it "returns false for past activities that are completed" do
      create(:activity, end_date: Date.today - 1, status: :closed).should_not be_overdue
    end
    it "considers today's date to be a future activity" do
      create(:activity, end_date: Date.today    , status: :open).should_not be_overdue
    end
    it "handle's nil dates" do
      create(:activity, end_date: nil           , status: :open).should_not be_overdue
    end
  end

  context ".user_ids=" do
    let(:users)        { create_list(:user, 2) }
    subject(:activity) { create(:activity) }
    it "supports normal ids" do
      activity.users.should be_blank
      activity.user_ids = users.collect(&:id)
      activity.users(true).should match_array(users)
    end
    it "supports strings in arrays" do
      activity.users.should be_blank
      activity.user_ids = users.collect(&:id).collect(&:to_s)
      activity.users(true).should match_array(users)
    end
    it "supports single ids" do
      activity.users.should be_blank
      activity.user_ids = users.first.id
      activity.users(true).should match_array([users.first])
    end
    it "supports comma separated ids" do
      activity.users.should be_blank
      activity.user_ids = "#{users.first.id},#{users.second.id}"
      activity.users(true).should match_array(users)
    end
  end

  describe ".parse_students_and_groups" do
    let!(:students)           { create_list(:student, 3) }
    let!(:groups)             { create_list(:group,   3) }
    let(:students_and_groups) { nil }
    subject(:activity)        { create(:activity, students_and_groups: students_and_groups) }

    its(:students) { should be_blank }
    its(:groups)   { should be_blank }

    context "with student ids" do
      let(:students_and_groups) { students.collect { |s| "s-#{s.id}" }.join(",") }
      its(:students)            { should match_array(students) }
    end
    context "with group ids" do
      let(:students_and_groups) { groups.collect { |g| "g-#{g.id}" }.join(",") }
      its(:groups)              { should match_array(groups) }
    end
    context "with student and group ids" do
      let(:students_and_groups) { "s-#{students.first.id},g-#{groups.first.id}"}
      its(:students)            { should == [students.first] }
      its(:groups)              { should == [groups.first] }
    end
    context "with invalid data" do
      let(:students_and_groups) { "[],zomg,123,s-#{students.first.id},g-#{groups.first.id}"}
      its(:students)            { should == [students.first] }
      its(:groups)              { should == [groups.first] }
    end
    context "with duplicates" do
      let(:students_and_groups) { ([ "s-#{students.first.id}", "g-#{groups.first.id}" ] * 2).join(",") }
      its(:students)            { should == [students.first] }
      its(:groups)              { should == [groups.first] }
    end
  end
  describe ".students_and_groups_select2_data" do
    let(:students)     { create_list(:student, 3) }
    let(:groups)       { create_list(:group,   3) }
    subject(:activity) { create(:activity, students: students, groups: groups) }

    its(:students_and_groups_select2_data) { should have(6).items }
    its(:students_and_groups_select2_data) { should include(id: "s-#{students.first.id}",  text: students.first.name) }
    its(:students_and_groups_select2_data) { should include(id: "s-#{students.second.id}", text: students.second.name) }
    its(:students_and_groups_select2_data) { should include(id: "s-#{students.third.id}",  text: students.third.name) }
    its(:students_and_groups_select2_data) { should include(id: "g-#{groups.first.id}",    text: groups.first.name) }
    its(:students_and_groups_select2_data) { should include(id: "g-#{groups.second.id}",   text: groups.second.name) }
    its(:students_and_groups_select2_data) { should include(id: "g-#{groups.third.id}",    text: groups.third.name) }
  end

  describe ".users_select2_data" do
    let(:users)        { create_list(:user, 2) }
    subject(:activity) { create(:activity, users: users) }

    its(:users_select2_data) { should have(2).items }
    its(:users_select2_data) { should include(id: users.first.id,  text: "#{users.first.name}, #{users.first.email}") }
    its(:users_select2_data) { should include(id: users.second.id, text: "#{users.second.name}, #{users.second.email}") }
  end


  describe "#in_instance" do
    let(:suite1)     { create(:suite) }
    let(:suite2)     { create(:suite,    instance: create(:instance)) }
    let!(:activity1) { create(:activity, suite:    suite1) }
    let!(:activity2) { create(:activity, suite:    suite2) }

    subject { Activity.in_instance(suite1.instance_id).all }
    it      { should match_array([ activity1 ])}
  end

  describe "#where_suite_member" do
    let(:user)                    { create(:superuser) }
    let(:contributed_suite)       { create(:suite) }
    let(:managed_suite)           { create(:suite) }
    let(:not_allowed_suite)       { create(:suite) }
    let!(:allowed_activities)     { create_list(:activity, 3, suite: contributed_suite) + create_list(:activity, 3, suite: managed_suite) }
    let!(:not_allowed_activities) { create_list(:activity, 3, suite: not_allowed_suite) }

    before(:each) do
      user.add_role :suite_member,  contributed_suite
      user.add_role :suite_manager, managed_suite
    end

    subject { Activity.where_suite_member(user).all }

    it { should have(6).items }
    it { should match_array(allowed_activities) }
  end
end
