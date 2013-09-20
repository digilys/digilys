require 'spec_helper'

describe TableState do
  context "factories" do
    context "default" do
      subject { build(:table_state) }
      it { should be_valid }
    end
    context "invalid" do
      subject { build(:invalid_table_state) }
      it { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:data) }
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:base) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:base) }
  end

  context ".ensure_json_data" do
    subject { create(:table_state, data: { foo: "bar" }.to_json) }
    its(:data) { should include("foo" => "bar") }

    context "with invalid data" do
      subject { create(:table_state, data: "foobarbaz") }
      its(:data) { should be_nil }
    end
  end
end
