require 'spec_helper'

describe Suite do
  context "factory" do
    subject { build(:suite) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
  end

  context "#new_from_template" do
    let(:template)     { create(:suite, is_template: true) }
    let!(:evaluations) { create_list(:evaluation, 3, suite: template) }
    let!(:meetings)    { create_list(:meeting,    3, suite: template) }
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

  context "#templates" do
    let!(:templates) { create_list(:suite, 3, is_template: true) }
    let!(:regular)   { create_list(:suite, 3, is_template: false) }
    it "restricts the query to templates only" do
      Suite.template.all.should match_array(templates)
    end
  end
  context "#regular" do
    let!(:templates) { create_list(:suite, 3, is_template: true) }
    let!(:regular)   { create_list(:suite, 3, is_template: false) }
    it "restricts the query to regular suites only" do
      Suite.regular.all.should match_array(regular)
    end
  end
end
