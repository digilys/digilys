require 'spec_helper'

describe Meeting do
  context "factory" do
    subject { build(:meeting) }
    it { should be_valid }
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:suite_id) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:date) }
    it { should allow_mass_assignment_of(:completed) }
    it { should allow_mass_assignment_of(:notes) }
  end
  context "validation" do
    it { should     validate_presence_of(:suite) }
    it { should     validate_presence_of(:name) }
    it { should_not validate_presence_of(:date) }

    context "with regular suite" do
      subject { build(:meeting, suite: create(:suite, is_template: false)) }
      it { should     validate_presence_of(:date) }
      it { should     allow_value("2013-04-29").for(:date) }
      it { should_not allow_value("201304-29").for(:date) }
    end
  end

  context ".has_regular_suite?" do
    context "with no suite" do
      subject { build(:meeting, suite: nil).has_regular_suite? }
      it { should be_false }
    end
    context "with template suite" do
      subject { build(:meeting, suite: create(:suite, is_template: true)).has_regular_suite? }
      it { should be_false }
    end
    context "with regular suite" do
      subject { build(:meeting, suite: create(:suite, is_template: false)).has_regular_suite? }
      it { should be_true }
    end
  end

  context ".overdue?" do
    it "returns true for past meetings that are not completed" do
      create(:meeting, date: Date.today - 1, completed: false).should     be_overdue
    end
    it "returns false for future meetings" do
      create(:meeting, date: Date.today + 1, completed: false).should_not be_overdue
    end
    it "returns false for past meetings that are completed" do
      create(:meeting, date: Date.today - 1, completed: true ).should_not be_overdue
    end
    it "considers today's date to be a future meeting" do
      create(:meeting, date: Date.today    , completed: false).should_not be_overdue
    end
  end
end