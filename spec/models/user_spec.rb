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
    context "admin" do
      subject { build(:superuser) }
      it { should be_valid }
    end
    context "invalid" do
      subject { build(:invalid_user) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:email) }
    it { should allow_mass_assignment_of(:password) }
    it { should allow_mass_assignment_of(:password_confirmation) }
    it { should allow_mass_assignment_of(:remember_me) }
    it { should allow_mass_assignment_of(:role_ids) }
    it { should allow_mass_assignment_of(:name) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
  end
end
