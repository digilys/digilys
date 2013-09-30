require 'spec_helper'

describe Suite do
  context "factory" do
    subject { build(:suite) }
    it { should be_valid }

    context "invalid" do
      subject { build(:invalid_suite) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:is_template) }
    it { should allow_mass_assignment_of(:instance) }
    it { should allow_mass_assignment_of(:instance_id) }
    it { should allow_mass_assignment_of(:evaluations_attributes) }
    it { should allow_mass_assignment_of(:meetings_attributes) }
    it { should allow_mass_assignment_of(:participants_attributes) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:instance) }
  end

  describe ".generic_evaluations" do
    subject { create(:suite, generic_evaluations: nil) }
    its(:generic_evaluations) { should == [] }

    context "with existing data" do
      subject { create(:suite, generic_evaluations: [1,2,3]) }
      its(:generic_evaluations) { should == [1,2,3] }
    end
  end
  describe ".student_data" do
    subject { create(:suite, student_data: nil) }
    its(:student_data) { should == [] }

    context "with existing data" do
      subject { create(:suite, student_data: %w(foo bar baz)) }
      its(:student_data) { should == %w(foo bar baz) }
    end
  end

  describe "#new_from_template" do
    let(:template)     { create(:suite, is_template: true) }
    let!(:evaluations) { create_list(:suite_evaluation, 3, suite: template) }
    let!(:meetings)    { create_list(:meeting,          3, suite: template) }
    let(:suite)        { Suite.new_from_template(template) }

    subject            { suite }

    its(:name)        { should == template.name }
    its(:is_template) { should be_false }

    it "copies the template's evaluations" do
      # Names should be equal...
      suite.evaluations.collect(&:name).should match_array(evaluations.collect(&:name))

      # ... but none of the ids, see Evaluation#new_from_template
      ids = suite.evaluations.collect(&:id)
      (ids - evaluations.collect(&:id)).should match_array(ids)
    end

    it "copies the template's meetings" do
      # Names should be equal...
      suite.meetings.collect(&:name).should match_array(meetings.collect(&:name))

      # ... but none of the ids
      ids = suite.meetings.collect(&:id)
      (ids - meetings.collect(&:id)).should match_array(ids)
    end

    context "with attrs" do
      let(:suite) { Suite.new_from_template(template, name: "Overridden") }
      its(:name)  { should == "Overridden" }
    end
  end

  describe "#templates" do
    let!(:templates) { create_list(:suite, 3, is_template: true) }
    let!(:regular)   { create_list(:suite, 3, is_template: false) }
    it "restricts the query to templates only" do
      Suite.template.all.should match_array(templates)
    end
  end
  describe "#regular" do
    let!(:templates) { create_list(:suite, 3, is_template: true) }
    let!(:regular)   { create_list(:suite, 3, is_template: false) }
    it "restricts the query to regular suites only" do
      Suite.regular.all.should match_array(regular)
    end
  end
end
