require 'spec_helper'

describe Student do
  context "factory" do
    subject { build(:student) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
  end

  context ".add_to_groups" do
    let(:parent1) { create(:group) }
    let(:parent2) { create(     :group,    parent: parent1) }
    let(:groups)  { create_list(:group, 2, parent: parent2) }
    let(:student) { create(:student) }

    it "adds the student to all groups" do
      student.add_to_groups(groups)
      student.groups.should include(groups.first)
      student.groups.should include(groups.second)
    end
    it "adds the student to the parents of all groups as well" do
      student.add_to_groups(groups)
      student.groups.should include(parent1)
      student.groups.should include(parent2)
    end
    it "handles a single group" do
      student.add_to_groups(groups.first)
      student.groups.should include(groups.first)
    end
    it "handles a string with comma separated group ids" do
      student.add_to_groups("#{groups.first.id}, #{groups.second.id}")
      student.groups.should include(groups.first)
      student.groups.should include(groups.second)
    end
    it "does not add duplicates" do
      student.add_to_groups(groups)
      student.add_to_groups(groups.first)
      student.add_to_groups([parent1, parent2])
      student.groups(true).should match_array(groups + [parent1, parent2])
    end
  end
  context ".remove_from_groups" do
    let(:parent1) { create(:group) }
    let(:parent2) { create(     :group,    parent: parent1) }
    let(:groups)  { create_list(:group, 2, parent: parent2) }
    let(:student) { create(:student) }
    before(:each) { student.add_to_groups(groups) } # Added to parents as well, see specs for .add_to_groups

    it "removes the student from all groups" do
      student.remove_from_groups(groups)
      student.groups.should_not include(groups.first)
      student.groups.should_not include(groups.second)
    end
    it "removes the student from all groups' parents as well" do
      student.remove_from_groups(groups)
      student.groups.should_not include(parent1)
      student.groups.should_not include(parent2)
    end
    it "removes the student from all groups' children as well" do
      student.remove_from_groups(parent1)
      student.groups.should_not include(parent2)
      student.groups.should_not include(groups.first)
      student.groups.should_not include(groups.second)
    end
    it "handles a single group" do
      student.remove_from_groups(groups.first)
      student.groups.should_not include(groups.first)
    end
    it "handles an array of group ids" do
      student.remove_from_groups(groups.collect(&:id).collect(&:to_s))
      student.groups.should_not include(groups.first)
      student.groups.should_not include(groups.second)
    end
  end
end
