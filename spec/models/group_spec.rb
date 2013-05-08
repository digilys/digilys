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
end