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
    it { should validate_presence_of(:suite) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:date) }

    it { should     allow_value("2013-04-29").for(:date) }
    it { should_not allow_value("201304-29").for(:date) }
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
