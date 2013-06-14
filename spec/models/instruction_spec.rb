require 'spec_helper'

describe Instruction do
  context "factories" do
    context "default" do
      subject { build(:instruction) }
      it      { should be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:body) }
    it { should allow_mass_assignment_of(:for_page) }
    it { should allow_mass_assignment_of(:title) }
  end
  context "validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:for_page) }
  end

  context "#for_controller_action" do
    let!(:instruction) { create(:instruction, for_page: "template/suites/new") }
    subject            { Instruction.for_controller_action("template/suites", "new") }
    it                 { should == instruction }
  end
end
