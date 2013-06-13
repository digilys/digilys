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

    context "Suite contributor" do
      let(:contributed) { create(:suite, is_template: false) }
      let(:none)        { create(:suite, is_template: false) }

      before(:each) do
        user.add_role :suite_contributor, contributed
      end

      it { should_not be_able_to(:view,          none) }
      it { should_not be_able_to(:contribute_to, none) }

      it { should_not be_able_to(:view,          none) }
      it { should_not be_able_to(:contribute_to, none) }
    end
  end

  context "Admin" do
    let(:user) { create(:admin) }
    it         { should be_able_to(:manage, :all) }
  end

  context "Superuser" do
    let(:user) { create(:superuser) }
    it         { should     be_able_to(:manage,  :all) }
    it         { should_not be_able_to(:manage,  User) }
    it         { should_not be_able_to(:destroy, Student) }

    context "for suites" do
      let(:managed)  { create(:suite, is_template: false) }
      let(:none)     { create(:suite, is_template: false) }
      let(:template) { create(:suite, is_template: true) }

      before(:each) do
        user.add_role :suite_manager, managed
      end

      it { should_not be_able_to(:manage,        Suite) }
      it { should     be_able_to(:create,        Suite) }

      it { should_not be_able_to(:view,          none) }
      it { should_not be_able_to(:update,        none) }
      it { should_not be_able_to(:destroy,       none) }

      it { should     be_able_to(:view,          managed) }
      it { should     be_able_to(:contribute_to, managed) }
      it { should     be_able_to(:update,        managed) }
      it { should     be_able_to(:destroy,       managed) }

      it { should     be_able_to(:view,          template) }
      it { should     be_able_to(:update,        template) }
      it { should_not be_able_to(:destroy,       template) }
    end
  end
end
