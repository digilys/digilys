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

    context "Suite roles" do
      let(:suite)             { create(:suite, is_template: false) }
      let(:other)             { create(:suite, is_template: false) }

      let(:associations)       { [
        build(:participant,      suite: suite),
        build(:suite_evaluation, suite: suite),
        build(:meeting,          suite: suite),
        build(:activity,         suite: suite),
        build(:table_state,      base:  suite),
      ] }
      let(:other_associations) { [
        build(:participant,      suite: other),
        build(:suite_evaluation, suite: other),
        build(:meeting,          suite: other),
        build(:activity,         suite: other),
        build(:table_state,      base:  other),
      ] }


      it "gives full privileges to their own suites to managers" do
        user.add_role :suite_manager, suite

        ability.should     be_able_to(:view,    suite)
        ability.should     be_able_to(:change,  suite)
        ability.should     be_able_to(:destroy, suite)

        ability.should_not be_able_to(:view,    other)
        ability.should_not be_able_to(:change,  other)
        ability.should_not be_able_to(:destroy, other)

        associations.each do |association|
          ability.should     be_able_to(:create,  association)
          ability.should     be_able_to(:view,    association)
          ability.should     be_able_to(:change,  association)
          ability.should     be_able_to(:destroy, association)
        end

        other_associations.each do |association|
          ability.should_not be_able_to(:create,  association)
          ability.should_not be_able_to(:view,    association)
          ability.should_not be_able_to(:change,  association)
          ability.should_not be_able_to(:destroy, association)
        end
      end
      it "gives all but destroy privilieges on their own suites to contributors" do
        user.add_role :suite_contributor, suite

        ability.should     be_able_to(:view,    suite)
        ability.should     be_able_to(:change,  suite)
        ability.should_not be_able_to(:destroy, suite)

        ability.should_not be_able_to(:view,    other)
        ability.should_not be_able_to(:change,  other)
        ability.should_not be_able_to(:destroy, other)

        associations.each do |association|
          ability.should     be_able_to(:create,  association)
          ability.should     be_able_to(:view,    association)
          ability.should     be_able_to(:change,  association)
          ability.should     be_able_to(:destroy, association)
        end

        other_associations.each do |association|
          ability.should_not be_able_to(:create,  association)
          ability.should_not be_able_to(:view,    association)
          ability.should_not be_able_to(:change,  association)
          ability.should_not be_able_to(:destroy, association)
        end
      end
      it "gives readonly privileges on their own suites to members" do
        user.add_role :suite_member, suite

        ability.should     be_able_to(:view,    suite)
        ability.should_not be_able_to(:change,  suite)
        ability.should_not be_able_to(:destroy, suite)

        ability.should_not be_able_to(:view,    other)
        ability.should_not be_able_to(:change,  other)
        ability.should_not be_able_to(:destroy, other)

        *readonly, table_state = associations

        readonly.each do |association|
          ability.should_not be_able_to(:create,  association)
          ability.should     be_able_to(:view,    association)
          ability.should_not be_able_to(:change,  association)
          ability.should_not be_able_to(:destroy, association)
        end

        ability.should     be_able_to(:create,  table_state)
        ability.should     be_able_to(:view,    table_state)
        ability.should     be_able_to(:change,  table_state)
        ability.should     be_able_to(:destroy, table_state)

        other_associations.each do |association|
          ability.should_not be_able_to(:create,  association)
          ability.should_not be_able_to(:view,    association)
          ability.should_not be_able_to(:change,  association)
          ability.should_not be_able_to(:destroy, association)
        end
      end
      it "allows suite members to report results" do
        user.add_role :suite_member, suite
        ability.should be_able_to(:report, build(:suite_evaluation, suite: suite))
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
    end
  end

  context "Admin" do
    let(:user) { create(:admin) }
    it         { should be_able_to(:manage, :all) }
  end

  context "Superuser" do
    let(:user)     { create(:superuser) }

    it { should     be_able_to(:manage,  Student) }
    it { should_not be_able_to(:destroy, Student) }

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
  end
end
