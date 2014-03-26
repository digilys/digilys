require 'spec_helper'

describe Setting do
  context "factories" do
    context "default" do
      subject { build(:setting) }
      it { should be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:data) }
    it { should allow_mass_assignment_of(:customizer) }
    it { should allow_mass_assignment_of(:customizable) }
  end

  context "#for" do
    let(:settings) { create_list(:setting, 5) }
    it "filters on customizables" do
      expect(Setting.for(settings.first.customizable)).to match_array([ settings.first ])
    end
  end
end
