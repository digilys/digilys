require 'spec_helper'

describe Participant do
  context "factory" do
    context "default" do
      subject { build(:participant) }
      it { should be_valid }
    end
    context "male" do
      subject { build(:male_participant) }
      it { should be_valid }
    end
    context "female" do
      subject { build(:female_participant) }
      it { should be_valid }
    end
  end

  context "validation" do
    it { should validate_presence_of(:student) }
    it { should validate_presence_of(:suite) }
    it { should validate_uniqueness_of(:student_id).scoped_to(:suite_id) }

    context ".student_and_suite_must_have_the_same_instance" do
      let(:instance) { create(:instance) }
      let(:suite)    { create(:suite,      instance: instance) }
      let(:same)     { create(:student,    instance: instance) }
      let(:other)    { create(:student,    instance: create(:instance)) }
      subject        { build(:participant, suite:    suite,            student: nil) }

      it { should     allow_value(same).for(:student) }
      it { should_not allow_value(other).for(:student) }
    end
  end

  describe ".name" do
    let(:student) { create(:student) }
    subject { create(:participant, student: student).name }
    it { should == student.name }
  end

  describe ".group_names" do
    let(:groups)  { create_list(:group, 2)}
    let(:student) { create(:student) }
    before(:each) { student.groups = groups }
    subject { create(:participant, student: student).group_names.split(/\s*,\s*/) } # Split by comma so we can test by comparing arrays
    it { should match_array(groups.collect(&:name)) }
  end


  describe ".add_group_users_to_suite" do
    let(:user)    { create(:user) }
    let(:group)   { create(:group,   users:  [user]) }
    let(:student) { create(:student, groups: [group]) }

    subject       { create(:participant, student: student, group: group).suite }

    its(:users)   { should include(user) }
  end

  describe ".update_evaluation_statuses!" do
    let(:suite) { create(:suite) }
    let(:evaluation) { create(:suite_evaluation, suite: suite) }
    let(:participants) { create_list(:participant, 2, suite: suite) }
    let!(:results) { participants.collect { |p| create(:result, evaluation: evaluation, student: p.student) } }

    it "updates the suite's evaluations' statuses" do
      evaluation.update_status!
      evaluation.reload
      evaluation.status.should == "complete"
      participant = create(:participant, suite: suite)
      evaluation.reload
      evaluation.status.should == "partial"
      participant.destroy
      evaluation.reload
      evaluation.status.should == "complete"
    end
  end


  describe "#with_gender" do
    let!(:male_participants)   { create_list(:male_participant, 3) }
    let!(:female_participants) { create_list(:female_participant, 3) }

    subject { Participant.with_gender(:female).all }
    it      { should match_array(female_participants) }
  end

  describe "#with_student_ids" do
    let(:student1)      { create(:student) }
    let(:student2)      { create(:student) }
    let(:student3)      { create(:student) }
    let!(:participant1) { create(:participant, student: student1) }
    let!(:participant2) { create(:participant, student: student2) }
    let!(:participant3) { create(:participant, student: student3) }

    subject { Participant.with_student_ids([ student1.id, student2.id ]).all }
    it      { should match_array([participant1, participant2])}
  end
  describe "#with_implicit_group_ids" do
    let(:group1) { create(:group) }
    let(:group2) { create(:group) }
    let(:group3) { create(:group) }
    let(:student1)      { create(:student) }
    let(:student2)      { create(:student) }
    let(:student3)      { create(:student) }
    let!(:participant1) { create(:participant, student: student1) }
    let!(:participant2) { create(:participant, student: student2) }
    let!(:participant3) { create(:participant, student: student3) }

    before(:each) do
      student1.groups << group1
      student2.groups << group2
      student3.groups << group3
    end

    subject { Participant.with_implicit_group_ids([ group1.id, group2.id ]).all }
    it      { should match_array([participant1, participant2])}
  end
end
