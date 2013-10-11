require 'spec_helper'

describe User do
  context "factories" do
    context "default" do
      subject { build(:user) }
      it { should be_valid }
    end
    context "admin" do
      subject { build(:admin) }
      it { should be_valid }
    end
    context "superuser" do
      subject { build(:superuser) }
      it { should be_valid }
    end
    context "invalid" do
      subject { build(:invalid_user) }
      it { should_not be_valid }
    end
    context "invisible_user" do
      subject { build(:invisible_user) }
      it { should be_valid }
    end
  end
  context "accessible attributes" do
    it { should     allow_mass_assignment_of(:email) }
    it { should     allow_mass_assignment_of(:password) }
    it { should     allow_mass_assignment_of(:password_confirmation) }
    it { should     allow_mass_assignment_of(:remember_me) }
    it { should     allow_mass_assignment_of(:role_ids) }
    it { should     allow_mass_assignment_of(:name) }
    it { should_not allow_mass_assignment_of(:invisible) }
    it { should     allow_mass_assignment_of(:active_instance_id) }
    it { should_not allow_mass_assignment_of(:preferences) }

    # Virtual
    it { should     allow_mass_assignment_of(:name_ordering) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:active_instance).on(:create) }
  end

  context ".grant_membership_to_active_instance" do
    subject(:user) { create(:user) }
    it             { should have_role(:member, user.active_instance) }

    context "on update" do
      subject(:user) { create(:user) }

      before(:each) do
        user.active_instance = create(:instance)
        user.save
      end

      it { should_not have_role(:member, user.active_instance) }
    end
  end

  context "#visible" do
    let!(:users)           { create_list(:user,           2) }
    let!(:invisible_users) { create_list(:invisible_user, 2) }
    subject                { User.visible.all }
    it                     { should match_array(users) }
  end

  context ".save_setting!" do
    let(:user)  { create(:user) }
    let(:suite) { create(:suite) }

    it "creates a new setting for the user if none exists" do
      user.settings.should be_blank
      user.save_setting!(suite, foo: "bar")

      user.settings(true).should      have(1).items
      user.settings.first.data.should == { "foo" => "bar" }
    end
    it "overrides existing settings, leaving existing keys untouched" do
      user.settings.create(customizable: suite, data: { "foo" => "baz", "zomg" => "lol" })
      user.save_setting!(suite, foo: "bar")

      user.settings(true).should      have(1).items
      user.settings.first.data.should include("foo"  => "bar")
      user.settings.first.data.should include("zomg" => "lol")
    end
  end

  context ".instances" do
    let(:member_of)      { create_list(:instance, 2) }
    let!(:not_member_of) { create_list(:instance, 2) }
    subject(:user)       { create(:user) }

    before(:each) do
      member_of.each do |i|
        user.add_role :member, i
      end
    end

    its(:instances) { should match_array(member_of + [ user.active_instance ])}
  end

  context ".name_ordering" do
    let(:ordering)      { :last_name }
    subject(:user)      { build(:user, preferences: { "name_ordering" => ordering })}
    its(:name_ordering) { should == ordering }

    context "defaults to first_name" do
      let(:ordering)      { nil }
      its(:name_ordering) { should == :first_name }
    end
  end

  context ".name_ordering=" do
    let(:ordering)      { nil }
    subject(:user)      { build(:user) }
    before(:each)       { user.name_ordering = ordering }
    its(:name_ordering) { should == :first_name }

    context "with a string" do
      let(:ordering)      { "last_name" }
      its(:name_ordering) { should == :last_name }
    end
    context "with an unknown value" do
      let(:foo)           { :zomg }
      its(:name_ordering) { should == :first_name }
    end
  end
end
