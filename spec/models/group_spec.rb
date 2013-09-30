require 'spec_helper'

describe Group do
  context "factory" do
    subject { build(:group) }
    it { should be_valid }

    context "invalid" do
      subject { build(:invalid_group) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:parent_id) }
    it { should allow_mass_assignment_of(:instance) }
    it { should allow_mass_assignment_of(:instance_id) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:instance) }

    context ".must_belong_to_parent_instance" do
      let(:parent) { create(:group, instance: create(:instance)) }
      subject      { build(:group,  parent: parent) }

      it           { should     allow_value(parent.instance).for(:instance) }
      it           { should_not allow_value(create(:instance)).for(:instance) }

      context "without parent" do
        let(:parent) { nil }
        it { should allow_value(create(:instance)).for(:instance) }
      end
    end
  end

  context "#with_parents" do
    let(:parent1) { create(:group, name: "parent1") }
    let(:parent2) { create(:group, name: "parent2", parent: parent1) }
    let(:parent3) { create(:group, name: "parent3", parent: parent2) }
    let(:group)   { create(:group, name: "subject", parent: parent3) }

    it "does nothing for 0 or less parents" do
      Group.with_parents(0).where(id: group.id).should == [group]
    end

    it "makes parents queryable" do
      Group.with_parents(2).where(
        "parent_1.name" => "parent3",
        "parent_2.name" => "parent2"
      ).should == [group]
    end

    it "joins only n parents" do
      expect {
        Group.with_parents(1).where(
          "parent_2.name" => "parent2"
        ).all
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  context "#top_level" do
    let!(:top_level)    { create_list(:group, 3) }
    let!(:second_level) { create_list(:group, 3, parent: top_level.first) }
    let!(:third_level)  { create_list(:group, 3, parent: second_level.second) }

    it "only matches groups without parents" do
      Group.top_level.all.should match_array(top_level)
    end
  end

  context ".add_students" do
    let(:parent1)  { create(:group) }
    let(:parent2)  { create(:group, parent: parent1) }
    let(:group)    { create(:group, parent: parent2) }
    let(:students) { create_list(:student, 2) }

    it "adds students to the group" do
      group.add_students(students)
      group.students.should match_array(students)
    end
    it "adds the students to the group's parents as well" do
      group.add_students(students)
      parent1.students(true).should match_array(students)
      parent2.students(true).should match_array(students)
    end
    it "handles a single student" do
      group.add_students(students.last)
      group.students.should == [students.last]
    end
    it "does not touch already added students" do
      group.add_students(students.first)
      group.add_students(students.last)
      group.students.should match_array(students)
    end
    it "handles a string with comma separated student ids" do
      group.add_students("#{students.first.id}, #{students.last.id}")
      group.students.should match_array(students)
    end
    it "handles an empty string" do
      group.add_students("")
      group.students.should be_blank
    end
    it "does not add duplicates" do
      group.add_students(students)
      group.add_students(students)
      parent1.add_students(students)
      parent1.add_students(students)

      group.students(true).should   match_array(students)
      parent1.students(true).should match_array(students)
    end
  end

  context ".remove_students" do
    let(:parent1)  { create(:group) }
    let(:parent2)  { create(:group, parent: parent1) }
    let(:group)    { create(:group, parent: parent2) }
    let(:students) { create_list(:student, 2) }
    before(:each)  { group.add_students(students) } # Added to parents as well, see specs for .add_students

    it "removes students from the group" do
      group.remove_students(students)
      group.students.should be_blank
    end
    it "removes the students from the group's parents as well" do
      group.remove_students(students)
      parent1.students(true).should be_blank
      parent2.students(true).should be_blank
    end
    it "removes the students from the group's children as well" do
      parent1.remove_students(students)
      parent2.students(true).should be_blank
      group.students(true).should be_blank
    end
    it "handles a single student" do
      group.remove_students(students.first)
      group.students.should == [students.second]
    end
    it "handles an array of student ids" do
      group.remove_students(students.collect(&:id).collect(&:to_s))
      group.students.should be_blank
    end
  end

  context ".add_users" do
    let(:group) { create(:group) }
    let(:users) { create_list(:user, 3) }

    it "adds users from a comma separated list of user ids" do
      group.add_users(users.collect(&:id).join(","))
      group.users(true).should match_array(users)
    end
    it "handles an empty string" do
      group.add_users("")
      group.users(true).should be_blank
    end
    it "does not add duplicates" do
      group.users << users.first
      group.add_users("#{users.first.id},#{users.first.id}")
      group.users(true).should == [users.first]
    end
  end

  context ".remove_users" do
    let(:group)   { create(:group) }
    let(:users)   { create_list(:user, 3) }
    before(:each) { group.users = users }

    it "removes users from an array of user ids" do
      group.remove_users(users.collect(&:id))
      group.users(true).should be_blank
    end
    it "handles an empty array" do
      group.remove_users([])
      group.users(true).should match_array(users)
    end
  end
end
