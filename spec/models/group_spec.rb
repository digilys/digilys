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
end
