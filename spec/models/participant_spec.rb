require 'spec_helper'

describe Participant do
  context "factory" do
    context "default" do
      subject { build(:participant) }
      it { should be_valid }
    end
    context "male" do
      subject { build(:male_participant) }
      it { should be_valid }
    end
    context "female" do
      subject { build(:female_participant) }
      it { should be_valid }
    end
  end

  context "validation" do
    it { should validate_presence_of(:student) }
    it { should validate_presence_of(:suite) }
    it { should validate_uniqueness_of(:student_id).scoped_to(:suite_id) }
  end

  describe ".name" do
    let(:student) { create(:student) }
    subject { create(:participant, student: student).name }
    it { should == student.name }
  end

  describe ".group_names" do
    let(:groups)  { create_list(:group, 2)}
    let(:student) { create(:student) }
    before(:each) { student.groups = groups }
    subject { create(:participant, student: student).group_names.split(/\s*,\s*/) } # Split by comma so we can test by comparing arrays
    it { should match_array(groups.collect(&:name)) }
  end


  describe "#with_gender" do
    let!(:male_participants)   { create_list(:male_participant, 3) }
    let!(:female_participants) { create_list(:female_participant, 3) }

    subject { Participant.with_gender(:female).all }
    it      { should match_array(female_participants) }
  end
end
