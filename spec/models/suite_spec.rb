require 'spec_helper'

describe Suite do
  context "factory" do
    subject { build(:suite) }
    it { should be_valid }

    context "complete template" do
      # A complete template should have all possible data set. This factory
      # is used to test regression when building objects from templates.
      #
      # The specs here use a blacklist for elements that should be excluded when
      # checking for associations. Thus, if a new attribute or association is
      # added to the model, it will automatically break this test, ensuring
      # that a decision is made whether the new attribute or association should be
      # included when creating an object from a template.
      subject(:template) { create(:complete_suite_template) }
      it                 { should be_a_complete_suite_template }

      it "has a complete evaluation" do
        expect(template.evaluations).not_to be_blank
        expect(template.evaluations.first).to be_a_complete_suite_evaluation
      end
      it "has a complete meeting" do
        expect(template.meetings).not_to be_blank
        expect(template.meetings.first).to be_a_complete_meeting
      end
    end
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
    it { should ensure_inclusion_of(:status).in_array(%w(open closed)) }
  end
  context "versioning", versioning: true do
    it { should be_versioned }
    it "stores the id as suite_id metadata" do
      suite = create(:suite)
      expect(suite.versions.last.suite_id).to eq suite.id
    end
  end
  context "associations" do
    context "color table" do
      let(:color_table) { build(:color_table, instance: nil) }
      it "creates a color table when creating a suite" do
        expect(create(:suite, color_table: nil).color_table).not_to be_blank
      end
      it "does not create a color table for templates" do
        expect(create(:suite, color_table: nil, is_template: true).color_table).to be_blank
      end
      it "does not overwrite an existing color table" do
        suite = create(:suite, color_table: color_table)
        expect(color_table.reload.suite).to eq suite
      end
    end
  end

  describe ".generic_evaluations" do
    subject { build(:suite, generic_evaluations: nil) }
    its(:generic_evaluations) { should == [] }

    context "with existing data" do
      subject { build(:suite, generic_evaluations: [1,2,3]) }
      its(:generic_evaluations) { should == [1,2,3] }
    end

    context "fetching" do
      let(:generics)       { create_list(:generic_evaluation, 2) }
      let(:wrong_type)     { create(:evaluation_template) }
      let(:wrong_instance) { create(:generic_evaluation, instance: create(:instance)) }

      it "returns evaluations fetched from the database" do
        suite = build(:suite, generic_evaluations: generics.collect(&:id))
        expect(suite.generic_evaluations(true)).to match_array(generics)
      end
      it "only returns generic evaluations" do
        suite = build(:suite, generic_evaluations: generics.collect(&:id) + [wrong_type.id])
        expect(suite.generic_evaluations(true)).to match_array(generics)
      end
      it "only returns evaluations from the same instance as the suite" do
        suite = build(:suite, generic_evaluations: generics.collect(&:id) + [wrong_instance.id])
        expect(suite.generic_evaluations(true)).to match_array(generics)
      end
    end
  end
  describe ".add_generic_evaluations" do
    subject(:suite) { build(:suite, generic_evaluations: nil) }

    it "adds all generic evaluations to the suite" do
      suite.add_generic_evaluations(123, 456)
      expect(suite.generic_evaluations).to match_array([123,456])
    end
    it "builds a new object when adding evaluations" do
      old = suite.generic_evaluations
      suite.add_generic_evaluations(123, 456)
      expect(suite.generic_evaluations).not_to be old
    end
  end
  describe ".remove_generic_evaluations" do
    subject(:suite) { build(:suite, generic_evaluations: [123,456,789]) }

    it "removes all generic evaluations from the suite" do
      suite.remove_generic_evaluations(123, 456)
      expect(suite.generic_evaluations).to match_array([789])
    end
    it "builds a new object when removing evaluations" do
      old = suite.generic_evaluations
      suite.remove_generic_evaluations(123, 456)
      expect(suite.generic_evaluations).not_to be old
    end
  end

  describe ".student_data" do
    subject(:suite)    { create(:suite, student_data: nil) }
    its(:student_data) { should == [] }

    it "only allows unique entries" do
      suite.student_data << "foo"
      suite.student_data << "foo"
      suite.student_data << "bar"
      suite.save
      expect(suite.reload.student_data).to match_array(%w(foo bar))
    end

    context "with existing data" do
      subject(:suite)    { create(:suite, student_data: %w(foo bar baz)) }
      its(:student_data) { should == %w(foo bar baz) }

      it "only allows unique entries" do
        suite.student_data << "foo"
        suite.save
        expect(suite.reload.student_data).to match_array(%w(foo bar baz))
      end
    end
  end
  describe ".add_student_data" do
    subject(:suite) { build(:suite, student_data: nil) }

    it "adds all student data to the suite" do
      suite.add_student_data("foo", "bar")
      expect(suite.student_data).to match_array(%w(foo bar))
    end
    it "builds a new object when adding student data" do
      old = suite.student_data
      suite.add_student_data("foo", "bar")
      expect(suite.student_data).not_to be old
    end
  end
  describe ".remove_student_data" do
    subject(:suite) { build(:suite, student_data: %w(foo bar baz)) }

    it "removes all student data from the suite" do
      suite.remove_student_data("foo", "bar")
      expect(suite.student_data).to match_array(%w(baz))
    end
    it "builds a new object when removing student data" do
      old = suite.student_data
      suite.remove_student_data("foo", "bar")
      expect(suite.student_data).not_to be old
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
      expect(suite.evaluations.collect(&:name)).to match_array(evaluations.collect(&:name))

      # ... but none of the ids, see Evaluation#new_from_template
      ids = suite.evaluations.collect(&:id)
      expect((ids - evaluations.collect(&:id))).to match_array(ids)
    end

    it "copies the template's meetings" do
      # Names and agendas should be equal...
      expect(suite.meetings.collect(&:name)).to match_array(meetings.collect(&:name))
      expect(suite.meetings.collect(&:agenda)).to match_array(meetings.collect(&:agenda))

      # ... but none of the ids
      ids = suite.meetings.collect(&:id)
      expect((ids - meetings.collect(&:id))).to match_array(ids)
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
      expect(Suite.template.all).to match_array(templates)
    end
  end
  describe "#regular" do
    let!(:templates) { create_list(:suite, 3, is_template: true) }
    let!(:regular)   { create_list(:suite, 3, is_template: false) }
    it "restricts the query to regular suites only" do
      expect(Suite.regular.all).to match_array(regular)
    end
  end
end
