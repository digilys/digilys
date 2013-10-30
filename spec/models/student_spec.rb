require 'spec_helper'

describe Student do
  context "factory" do
    subject { build(:student) }
    it { should be_valid }

    context "invalid" do
      subject { build(:invalid_student) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:personal_id) }
    it { should allow_mass_assignment_of(:first_name) }
    it { should allow_mass_assignment_of(:last_name) }
    it { should allow_mass_assignment_of(:gender) }
    it { should allow_mass_assignment_of(:data) }
    it { should allow_mass_assignment_of(:instance) }
    it { should allow_mass_assignment_of(:instance_id) }
  end
  context "validation" do
    it { should validate_presence_of(:personal_id) }
    it { should validate_uniqueness_of(:personal_id) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:instance) }
    it { should ensure_inclusion_of(:gender).in_array(%w(male female)) }
  end
  context ".validate_data_text" do
    it { should allow_value(nil).for(:data_text) }
    it { should allow_value("foo: bar\nbar: baz").for(:data_text) }
    it { should allow_value("\nfoo: bar\n\n   \n\nbar: baz\n").for(:data_text) }

    it { should_not allow_value("foo\nbar: baz").for(:data_text).with_message(/rad 1/i) }
    it { should_not allow_value("foo: bar\nbar: baz: foo").for(:data_text).with_message(/rad 2/i) }
    it { should_not allow_value("foo\nbar: baz: foo").for(:data_text).with_message(/rad 1,2/i) }
  end

  context ".touch_suites" do
    let!(:suite)       { create(:suite) }
    let!(:student)     { create(:student) }
    let!(:participant) { create(:participant, student: student, suite: suite) }

    it "touches the suites the student is a participant of" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        student.name << " updated"
        student.save

        updated_at.should < suite.reload.updated_at
      end
    end
  end

  context ".name" do
    subject { create(:student, first_name: "Foo", last_name: "Bar") }
    its(:name) { should == "Foo Bar" }
  end

  context ".data_text=" do
    subject(:student) { create(:student, data_text: text) }

    context "with empty values" do
      let(:text) { "foo:" }
      its(:data) { should have(1).items }
      its(:data) { should include("foo" => nil) }
    end
    context "with multiple rows" do
      let(:text) { "foo: bar\nbar: baz" }
      its(:data) { should have(2).items }
      its(:data) { should include("foo" => "bar") }
      its(:data) { should include("bar" => "baz") }
    end
    context "with empty rows" do
      let(:text) { "\n\nfoo: bar\n\n   \n\nbar: baz\n\n" }
      its(:data) { should have(2).items }
    end
    context "with an integer" do
      let(:text) { "foo: 2010" }
      its(:data) { should == { "foo" => 2010 } }
      it "returns an integer" do
        student.data["foo"].should be_an_instance_of(Fixnum)
      end
    end
    context "with a float" do
      context "using dots" do
        let(:text) { "foo: 1.2" }
        its(:data) { should == { "foo" => 1.2 } }
      end
      context "using comma" do
        let(:text) { "foo: 1,3" }
        its(:data) { should == { "foo" => 1.3 } }
      end
    end
    context "with a true value" do
      context "using ja" do
        let(:text) { "foo: ja" }
        its(:data) { should == { "foo" => true } }
      end
      context "using Ja" do
        let(:text) { "foo: Ja" }
        its(:data) { should == { "foo" => true } }
      end
      context "using yes" do
        let(:text) { "foo: yes" }
        its(:data) { should == { "foo" => true } }
      end
      context "using Yes" do
        let(:text) { "foo: Yes" }
        its(:data) { should == { "foo" => true } }
      end
      context "using sant" do
        let(:text) { "foo: sant" }
        its(:data) { should == { "foo" => true } }
      end
      context "using Sant" do
        let(:text) { "foo: Sant" }
        its(:data) { should == { "foo" => true } }
      end
      context "using true" do
        let(:text) { "foo: true" }
        its(:data) { should == { "foo" => true } }
      end
      context "using True" do
        let(:text) { "foo: True" }
        its(:data) { should == { "foo" => true } }
      end
    end
    context "with a false value" do
      context "using nej" do
        let(:text) { "foo: nej" }
        its(:data) { should == { "foo" => false } }
      end
      context "using Nej" do
        let(:text) { "foo: Nej" }
        its(:data) { should == { "foo" => false } }
      end
      context "using no" do
        let(:text) { "foo: no" }
        its(:data) { should == { "foo" => false } }
      end
      context "using No" do
        let(:text) { "foo: No" }
        its(:data) { should == { "foo" => false } }
      end
      context "using falskt" do
        let(:text) { "foo: falskt" }
        its(:data) { should == { "foo" => false } }
      end
      context "using Falskt" do
        let(:text) { "foo: Falskt" }
        its(:data) { should == { "foo" => false } }
      end
      context "using false" do
        let(:text) { "foo: false" }
        its(:data) { should == { "foo" => false } }
      end
      context "using False" do
        let(:text) { "foo: False" }
        its(:data) { should == { "foo" => false } }
      end
    end
  end
  context ".data_text" do
    subject { create(:student, data: data) }

    context "with nil" do
      let(:data) { nil }
      its(:data_text) { should be_nil }
    end
    context "with multiple values" do
      let(:data) { { foo: "bar", bar: 1 } }
      its(:data_text) { should == "foo: bar\nbar: 1" }
    end
    context "with float" do
      let(:data) { { foo: 1.2 } }
      its(:data_text) { should == "foo: 1,2" }
    end
    context "with true" do
      let(:data) { { foo: true } }
      its(:data_text) { should == "foo: Ja" }
    end
    context "with false" do
      let(:data) { { foo: false } }
      its(:data_text) { should == "foo: Nej" }
    end
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
    it "does not add groups from other instances" do
      student.add_to_groups(create_list(:group, 2, instance: create(:instance)))
      student.groups(true).should be_empty
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

  context ".generic_results" do
    subject(:student) { create(:student) }
    let!(:suite_results)   { [
      create(:result, student: student, evaluation: create(:suite_evaluation)),
      create(:result, student: student, evaluation: create(:suite_evaluation)),
      create(:result, student: student, evaluation: create(:suite_evaluation))
    ] }
    let!(:generic_results) { [
      create(:result, student: student, evaluation: create(:generic_evaluation)),
      create(:result, student: student, evaluation: create(:generic_evaluation)),
      create(:result, student: student, evaluation: create(:generic_evaluation))
    ] }

    its(:results)         { should match_array(generic_results + suite_results) }
    its(:generic_results) { should match_array(generic_results) }
  end

  context ".populate_generic_results" do
    let(:student)                   { create(:student) }
    let!(:generic_evaluations)      { create_list(:generic_evaluation, 3) }
    let!(:other_generic_evaluation) { create(     :generic_evaluation, instance: create(:instance)) }
    let!(:existing)                 { nil }
    before(:each)                   { student.populate_generic_results }
    subject(:results)               { student.generic_results }

    it { should have(3).items }

    it "has records for all generic evaluations" do
      results.collect(&:evaluation).should match_array(generic_evaluations)
    end
    it "has only unsaved records" do
      results.collect(&:new_record?).should match_array([true, true, true])
    end

    context "with partial existing results" do
      let(:existing) { create(:result, student: student, evaluation: generic_evaluations.first) }

      it { should have(3).items }

      it "has records for all generic evaluations" do
        results.collect(&:evaluation).should match_array(generic_evaluations)
      end
      it "has partially unsaved records" do
        results.collect(&:new_record?).should match_array([false, true, true])
      end
    end
    context "with complete existing results" do
      let(:existing) { [
        create(:result, student: student, evaluation: generic_evaluations.first),
        create(:result, student: student, evaluation: generic_evaluations.second),
        create(:result, student: student, evaluation: generic_evaluations.third)
      ] }

      it { should have(3).items }

      it "has records for all generic evaluations" do
        results.collect(&:evaluation).should match_array(generic_evaluations)
      end
      it "has partially unsaved records" do
        results.collect(&:new_record?).should match_array([false, false, false])
      end
    end
  end
end
