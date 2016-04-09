require 'spec_helper'

describe Ability do
  let(:user)        { nil }
  subject(:ability) { Ability.new(user) }

  context "User without roles" do
    let(:user)       { create(:user) }
    let(:other_user) { create(:user) }

    it               { should     be_able_to(:update, user) }
    it               { should_not be_able_to(:update, other_user) }

    it               { should     be_able_to(:search, User) }
    it               { should     be_able_to(:search, Evaluation) }

    it               { should     be_able_to(:view,   Student) }
    it               { should     be_able_to(:search, Student) }

    it               { should     be_able_to(:view,   Group) }
    it               { should     be_able_to(:search, Group) }

    it               { should     be_able_to(:index,  Suite) }

    it               { should     be_able_to(:index,  Instance) }

    it               { should     be_able_to(:list,   ColorTable) }

    context "Activity reporting" do
      let(:activity) { create(:activity) }
      let(:other)    { create(:activity) }

      it "allows users to report activites they are assigned to" do
        activity.users << user
        expect(ability).to     be_able_to(:report, activity)
        expect(ability).not_to be_able_to(:report, other)
      end
    end

    context "Instance member" do
      let(:member_of)     { create(:instance) }
      let(:not_member_of) { create(:instance) }

      before(:each) do
        user.add_role :member, member_of
      end

      it { should_not be_able_to(:select, not_member_of) }
      it { should     be_able_to(:select, member_of) }
      it { should_not be_able_to(:import, Instance) }
      it { should_not be_able_to(:control, Instance) }
    end

    context "Instance admin" do
      let!(:instance)             { create(:instance) }
      let!(:other_instance)       { create(:instance) }
      let!(:user)                 { create(:user, admin_instance: instance) }
      let!(:other_user)           { create(:user) }
      let!(:instance_member)      { create(:user) }
      let!(:admin)                { create(:admin) }
      let!(:suite)                { create(:suite, instance: instance) }
      let!(:other_suite)          { create(:suite, instance: other_instance) }
      let!(:template_suite)       { create(:suite, instance: instance, is_template: true) }
      let!(:evaluation)           { create(:suite_evaluation, suite: suite) }
      before(:each) do
        user.active_instance = instance
        instance_member.add_role(:member, instance)
        admin.add_role(:member, instance)
      end
      subject(:ability) { Ability.new(user) }
      it              { should be_able_to(:import, Instance) }
      it              { should be_able_to(:import_student_data, Instance) }
      it              { should_not be_able_to(:import_instructions, Instance) }
      it              { should_not be_able_to(:import_evaluation_templates, Instance) }
      it              { should_not be_able_to(:import_results, Instance) }

      # User
      it              { should be_able_to(:manage, instance_member) }
      it              { should be_able_to(:view, instance_member) }
      it              { should be_able_to(:edit, instance_member) }
      it              { should be_able_to(:change, instance_member) }
      it              { should be_able_to(:destroy, instance_member) }

      it              { should_not be_able_to(:manage, other_user) }
      it              { should_not be_able_to(:view, other_user) }
      it              { should_not be_able_to(:edit, other_user) }
      it              { should_not be_able_to(:change, other_user) }
      it              { should_not be_able_to(:destroy, other_user) }

      it              { should_not be_able_to(:manage, admin) }
      it              { should_not be_able_to(:view, admin) }
      it              { should_not be_able_to(:edit, admin) }
      it              { should_not be_able_to(:change, admin) }
      it              { should_not be_able_to(:destroy, admin) }

      # Role
      it              { should be_able_to(:manage, Role) }

      # Suite
      it              { should_not be_able_to(:create, Suite) }

      it              { should be_able_to(:manage, suite) }
      it              { should be_able_to(:view, suite) }
      it              { should be_able_to(:edit, suite) }
      it              { should be_able_to(:change, suite) }
      it              { should_not be_able_to(:destroy, suite) }

      it              { should_not be_able_to(:destroy, other_suite) }
      it              { should_not be_able_to(:view, other_suite) }
      it              { should_not be_able_to(:edit, other_suite) }
      it              { should_not be_able_to(:change, other_suite) }

      it              { should_not be_able_to(:destroy, template_suite) }
      it              { should_not be_able_to(:manage, template_suite) }
      it              { should_not be_able_to(:destroy, template_suite) }

      # Instance
      it              { should be_able_to(:control, Instance) }

      it              { should be_able_to(:view, instance) }
      it              { should be_able_to(:associate_users, instance) }

      it              { should_not be_able_to(:view, other_instance) }
      it              { should_not be_able_to(:associate_users, other_instance) }

      # Group
      it              { should be_able_to(:manage, Group) }
      it              { should be_able_to(:view, Group) }
      it              { should be_able_to(:copy, Group) }
      it              { should be_able_to(:create, Group) }
      it              { should be_able_to(:move_students, Group) }

      it              { should_not be_able_to(:edit, Group) }
      it              { should_not be_able_to(:update, Group) }
      it              { should_not be_able_to(:create_new, Group) }
      it              { should_not be_able_to(:destroy, Group) }
      it              { should_not be_able_to(:select_students, Group) }
      it              { should_not be_able_to(:add_students, Group) }
      it              { should_not be_able_to(:remove_students, Group) }
      it              { should_not be_able_to(:select_users, Group) }
      it              { should_not be_able_to(:add_users, Group) }
      it              { should_not be_able_to(:remove_users, Group) }
    end
  end

  context "Admin" do
    let(:user) { create(:admin) }
    it         { should be_able_to(:manage, :all) }
    it         { should be_able_to(:import, :all) }
    it         { should be_able_to(:import, Instance) }
    it         { should be_able_to(:import_student_data, Instance) }
    it         { should be_able_to(:import_instructions, Instance) }
    it         { should be_able_to(:import_evaluation_templates, Instance) }
    it         { should be_able_to(:import_results, Instance) }
    it         { should be_able_to(:manage, Role) }
  end

  context "Superuser" do
    let(:user)     { create(:superuser) }

    it { should     be_able_to(:manage,  Student) }
    it { should_not be_able_to(:destroy, Student) }

    it { should be_able_to(:manage, Role) }

    it { should     be_able_to(:manage,  Group) }

    it { should_not be_able_to(:manage,  Suite)}
    it { should     be_able_to(:create,  Suite)}
    it { should     be_able_to(:list,    Suite)}

    let(:regular)  { build(:suite, is_template: false) }
    let(:template) { build(:suite, is_template: true) }

    it { should     be_able_to(:view,    template)}
    it { should     be_able_to(:change,  template)}
    it { should_not be_able_to(:destroy, template)}

    it { should_not be_able_to(:view,    regular)}
    it { should_not be_able_to(:change,  regular)}
    it { should_not be_able_to(:destroy, regular)}

    it { should     be_able_to(:manage,  Evaluation) }

    let(:generic_evaluation)  { build(:generic_evaluation) }
    let(:suite_evaluation)    { build(:suite_evaluation) }

    it { should     be_able_to(:view,    generic_evaluation) }
    it { should     be_able_to(:change,  generic_evaluation) }
    it { should     be_able_to(:destroy, generic_evaluation) }

    it { should_not be_able_to(:view,    suite_evaluation) }
    it { should_not be_able_to(:change,  suite_evaluation) }
    it { should_not be_able_to(:destroy, suite_evaluation) }

    it { should     be_able_to(:create,  ColorTable) }
  end

  context "Suite roles" do
    let(:user)  { create(:user) }
    let(:suite) { create(:suite, is_template: false) }
    let(:other) { create(:suite, is_template: false) }

    let(:associations) { [
      build(:participant,       suite: suite),
      build(:suite_evaluation,  suite: suite),
      build(:meeting,           suite: suite),
      build(:activity,          suite: suite)
    ] }
    let(:other_associations) { [
      build(:participant,       suite: other),
      build(:suite_evaluation,  suite: other),
      build(:meeting,           suite: other),
      build(:activity,          suite: other)
    ] }


    it "gives full privileges to their own suites to managers" do
      user.add_role :suite_manager, suite

      expect(ability).to     be_able_to(:view,    suite)
      expect(ability).to     be_able_to(:change,  suite)
      expect(ability).to     be_able_to(:control, suite)

      expect(ability).not_to be_able_to(:view,    other)
      expect(ability).not_to be_able_to(:change,  other)
      expect(ability).not_to be_able_to(:control, other)

      associations.each do |association|
        expect(ability).to     be_able_to(:create,  association)
        expect(ability).to     be_able_to(:view,    association)
        expect(ability).to     be_able_to(:change,  association)
        expect(ability).to     be_able_to(:destroy, association)
      end

      other_associations.each do |association|
        expect(ability).not_to be_able_to(:create,  association)
        expect(ability).not_to be_able_to(:view,    association)
        expect(ability).not_to be_able_to(:change,  association)
        expect(ability).not_to be_able_to(:destroy, association)
      end
    end
    it "gives all but destroy privilieges on their own suites to contributors" do
      user.add_role :suite_contributor, suite

      expect(ability).to     be_able_to(:view,    suite)
      expect(ability).to     be_able_to(:change,  suite)
      expect(ability).not_to be_able_to(:control, suite)

      expect(ability).not_to be_able_to(:view,    other)
      expect(ability).not_to be_able_to(:change,  other)
      expect(ability).not_to be_able_to(:control, other)

      associations.each do |association|
        expect(ability).to be_able_to(:create,  association)
        expect(ability).to be_able_to(:view,    association)
        expect(ability).to be_able_to(:change,  association)
        expect(ability).to be_able_to(:destroy, association)
      end

      other_associations.each do |association|
        expect(ability).not_to be_able_to(:create,  association)
        expect(ability).not_to be_able_to(:view,    association)
        expect(ability).not_to be_able_to(:change,  association)
        expect(ability).not_to be_able_to(:destroy, association)
      end
    end
    it "gives readonly privileges on their own suites to members" do
      user.add_role :suite_member, suite

      expect(ability).to     be_able_to(:view,    suite)
      expect(ability).not_to be_able_to(:change,  suite)
      expect(ability).not_to be_able_to(:control, suite)

      expect(ability).not_to be_able_to(:view,    other)
      expect(ability).not_to be_able_to(:change,  other)
      expect(ability).not_to be_able_to(:control, other)

      associations.each do |association|
        expect(ability).not_to be_able_to(:create,  association)
        expect(ability).to     be_able_to(:view,    association)
        expect(ability).not_to be_able_to(:change,  association)
        expect(ability).not_to be_able_to(:destroy, association)
      end

      other_associations.each do |association|
        expect(ability).not_to be_able_to(:create,  association)
        expect(ability).not_to be_able_to(:view,    association)
        expect(ability).not_to be_able_to(:change,  association)
        expect(ability).not_to be_able_to(:destroy, association)
      end
    end
    it "allows suite members to report results" do
      user.add_role :suite_member, suite
      expect(ability).to be_able_to(:report, build(:suite_evaluation, suite: suite))
    end

    context "for color color table" do
      let(:color_table) { suite.color_table }

      it "gives view and change privileges to the color table" do
        expect(ability).not_to be_able_to(:view, color_table)
        expect(ability).not_to be_able_to(:edit, color_table)

        user.add_role(:suite_member, suite)
        expect(ability).to     be_able_to(:view, color_table)
        expect(ability).not_to be_able_to(:edit, color_table)

        user.add_role(:suite_contributor, suite)
        expect(ability).to     be_able_to(:view, color_table)
        expect(ability).to     be_able_to(:edit, color_table)
      end
    end
  end

  context "Color table" do
    let(:user)              { create(:user) }
    let(:suite_color_table) { create(:suite).color_table }

    it "delegates privileges to the suite" do
      expect(ability).not_to be_able_to(:view, suite_color_table)
      expect(ability).not_to be_able_to(:change, suite_color_table)

      user.add_role(:suite_member, suite_color_table.suite)
      expect(ability).to     be_able_to(:view, suite_color_table)
      expect(ability).not_to be_able_to(:change, suite_color_table)

      user.add_role(:suite_contributor, suite_color_table.suite)
      expect(ability).to     be_able_to(:view, suite_color_table)
      expect(ability).to     be_able_to(:change, suite_color_table)
    end
  end

  context "Table state" do
    let(:user)              { create(:user) }
    let(:suite_color_table) { create(:suite).color_table }
    let(:suite_table_state) { create(:table_state, base: suite_color_table) }

    it "delegates to change privileges on the base" do
      expect(ability).not_to be_able_to(:view,   suite_table_state)
      expect(ability).not_to be_able_to(:change, suite_table_state)

      user.add_role(:suite_member, suite_color_table.suite)
      expect(ability).to     be_able_to(:view,   suite_table_state)
      expect(ability).not_to be_able_to(:change, suite_table_state)

      user.add_role(:suite_contributor, suite_color_table.suite)
      expect(ability).to     be_able_to(:view,   suite_table_state)
      expect(ability).to     be_able_to(:change, suite_table_state)
    end
  end
end
