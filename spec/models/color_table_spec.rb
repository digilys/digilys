require 'spec_helper'

describe ColorTable do
  context "factory" do
    subject { build(:color_table) }
    it { should be_valid }

    context "invalid" do
      subject { build(:invalid_color_table) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:student_data) }
    it { should allow_mass_assignment_of(:instance) }
    it { should allow_mass_assignment_of(:instance_id) }
    it { should allow_mass_assignment_of(:suite) }
    it { should allow_mass_assignment_of(:suite_id) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:instance) }

    context "with suite" do
      subject { create(:suite).color_table }
      it { should_not allow_value(create(:instance)).for(:instance) }
    end
  end

  context "associations" do
    context "evaluations" do
      let(:suites)   { create_list(:suite_evaluation,   2) }
      let(:generics) { create_list(:generic_evaluation, 2) }
      subject {
        create(:color_table, evaluations: suites + generics)
      }

      its(:generic_evaluations) { should match_array(generics) }
      its(:suite_evaluations)   { should match_array(suites) }
    end
    context "students" do
      let(:suite)              { create(:suite) }
      let(:suite_evaluation)   { create(:suite_evaluation, suite: suite) }
      let(:other_evaluation)   { create(:suite_evaluation) }
      let(:generic_evaluation) { create(:generic_evaluation) }
      let(:participant)        { create(:participant, suite: suite) }
      let(:student1)           { participant.student }
      let(:student2)           { create(:student) }
      let(:student3)           { create(:student) }
      let!(:suite_result)      { create(:result, student: student1, evaluation: suite_evaluation)}
      let!(:other_result)      { create(:result, student: student2, evaluation: other_evaluation)}
      let!(:generic_result)    { create(:result, student: student3, evaluation: generic_evaluation)}
      let(:color_table)        { create(:color_table, evaluations: [ suite_evaluation, other_evaluation, generic_evaluation ]) }

      before(:each) do
        suite.color_table.evaluations << generic_evaluation
      end

      it "returns all students with results in non-generic evaluations connected to the color table" do
        expect(color_table.students).to match_array([student1, student2])
      end
      it "returns only the students from the suite for suite color tables" do
        expect(suite.color_table.students).to match_array([student1])
      end
    end
  end

  describe ".add_suite_evaluations" do
    let(:instance) { create(:instance) }
    let(:evaluation)  {
      {
        name: "z1",
        date: Date.today.to_s,
        type: "suite",
        max_result: 10
      }
    }
    let(:suite)       { Suite.create!(:name => "z", instance: instance, evaluations_attributes: { "0" => evaluation }) }
    let(:color_table) { suite.color_table }

    it "adds the suite's evaluations to the color table upon creation" do
      expect(suite.evaluations).to have(1).items
      expect(color_table.evaluations).to have(1).items
      expect(color_table.evaluations).to match_array(suite.evaluations)
    end
  end

  describe ".student_data" do
    subject(:color_table) { create(:color_table, student_data: nil) }
    its(:student_data)    { should == [] }

    it "only allows unique entries" do
      color_table.student_data << "foo"
      color_table.student_data << "foo"
      color_table.student_data << "bar"
      color_table.save
      expect(color_table.reload.student_data).to match_array(%w(foo bar))
    end

    context "with existing data" do
      subject(:color_table) { create(:color_table, student_data: %w(foo bar baz)) }
      its(:student_data)    { should == %w(foo bar baz) }

      it "only allows unique entries" do
        color_table.student_data << "foo"
        color_table.save
        expect(color_table.reload.student_data).to match_array(%w(foo bar baz))
      end
    end
  end

  describe ".group_hierarchy" do
    let!(:l1_group1)   { create(:group) }
    let!(:l1_group2)   { create(:group) }
    let!(:l2_group1)   { create(:group, parent: l1_group1) }
    let!(:l2_group2)   { create(:group, parent: l1_group1) }
    let!(:l3_group1)   { create(:group, parent: l2_group1) }
    let!(:l3_group2)   { create(:group, parent: l2_group1) }
    let!(:l3_group3)   { create(:group, parent: l2_group2) }

    let!(:student1)    { create(:student) }
    let!(:student2)    { create(:student) }

    let!(:evaluation1) { create(:generic_evaluation) }
    let!(:evaluation2) { create(:generic_evaluation) }

    let!(:result1)     { create(:result, student: student1, evaluation: evaluation1) }
    let!(:result2)     { create(:result, student: student2, evaluation: evaluation2) }

    let(:color_table) { create(:color_table) }

    before(:each) do
      student1.add_to_groups(l3_group1)
      student2.add_to_groups(l3_group3)

      color_table.evaluations = [ evaluation1, evaluation2 ]
    end

    subject(:groups) { color_table.group_hierarchy }

    it "orders the color table's associated groups by its hierarchy" do
      expect(groups).to eq [
        l1_group1,
          l2_group1,
            l3_group1,
          l2_group2,
            l3_group3
      ]
    end

    context "for suite color table" do
      let(:suite)        { create(:suite) }
      let!(:participant) { create(:participant, suite: suite, student: student1) }
      subject(:groups)   { suite.color_table.group_hierarchy }

      it "orders the suite's associated groups by its hierarchy" do
        expect(groups).to eq [
          l1_group1,
            l2_group1,
              l3_group1
        ]
      end
    end
  end


  describe "#regular" do
    let!(:regular) { create_list(:color_table, 2) }
    let!(:suite)   { create_list(:suite,       2).collect(&:color_table) }
    subject        { ColorTable.regular }
    it             { should match_array(regular) }
  end
  describe "#with_suites" do
    let!(:regular) { create_list(:color_table, 2) }
    let!(:suite)   { create_list(:suite,       2).collect(&:color_table) }
    subject        { ColorTable.with_suites }
    it             { should match_array(suite) }
  end
end
