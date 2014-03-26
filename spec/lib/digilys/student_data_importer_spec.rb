require 'spec_helper'
require 'digilys/student_data_importer'

describe Digilys::StudentDataImporter do
  let(:csv)            { "" }
  let(:instance)       { create(:instance) }
  let(:has_header_row) { false }

  subject(:importer)   { Digilys::StudentDataImporter.new(CSV.new(csv), instance.id, has_header_row) }

  describe ".parsed_attributes" do
    let(:csv) {
      <<-CSV
      School1 , Grade1 , 20000101-1234 , Lastname , Firstname , Flicka 
      CSV
    }

    subject(:parsed_attributes) { importer.parsed_attributes }

    it { should have(1).items }

    context "original row" do
      subject { parsed_attributes.first[:original_row] }
      it { should == [ "      School1 ", " Grade1 ", " 20000101-1234 ", " Lastname ", " Firstname ", " Flicka " ] }
    end
    context "attributes" do
      subject { parsed_attributes.first[:attributes] }

      its(:keys) { should have(6).items }

      it { should include(school: "School1") }
      it { should include(grade: "Grade1") }
      it { should include(personal_id: "20000101-1234") }
      it { should include(last_name: "Lastname") }
      it { should include(first_name: "Firstname") }
      it { should include(gender: :female) }
    end
    context "gender formats" do
      let(:csv) {
        <<-CSV
        School1 , Grade1 , 20000101-1234 , Lastname , Firstname , Flicka 
        School1 , Grade1 , 20000101-1235 , Lastname , Firstname , Kvinna
        School1 , Grade1 , 20000101-1236 , Lastname , Firstname , F
        School1 , Grade1 , 20000101-1237 , Lastname , Firstname , K
        School1 , Grade1 , 20000101-1238 , Lastname , Firstname , Pojke
        School1 , Grade1 , 20000101-1239 , Lastname , Firstname , Man
        School1 , Grade1 , 20000101-1240 , Lastname , Firstname , P
        School1 , Grade1 , 20000101-1241 , Lastname , Firstname , M
        CSV
      }
      subject { parsed_attributes.collect { |h| h[:attributes][:gender] } }
      it      { should == [ [:female] * 4, [:male] * 4 ].flatten }
    end
  end

  describe ".valid?" do
    context "with valid rows" do
      let(:csv) {
        <<-CSV
        School1 , Grade1 , 20000101-1234 , Lastname , Firstname , Flicka 
        School1 , Grade1 , 20000101-1238 , Lastname , Firstname , Pojke
        CSV
      }
      it { should be_valid }
    end
    context "with invalid rows" do
      let(:csv) {
        <<-CSV
        School1 , Grade1 ,, Lastname , Firstname , Flicka 
        School1 , Grade1 , 20000101-1238 , Lastname , Firstname , Pojke
        CSV
      }
      it { should_not be_valid }
    end
  end

  describe "count methods" do
    let(:csv) {
      <<-CSV
      School1 , Grade1 ,, Lastname , Firstname , Flicka 
      School1 , Grade1 , 20000101-1238 , Lastname , Firstname , Pojke
      CSV
    }

    before(:each) do
      importer.valid?
    end

    its(:valid_count)   { should == 1 }
    its(:invalid_count) { should == 1 }
  end

  describe ".invalid" do
    let(:csv) {
      <<-CSV.strip_heredoc
      School1 , Grade1 ,, Lastname , Firstname , Flicka 
      CSV
    }

    before(:each) do
      importer.valid?
    end

    subject { importer.invalid }

    it { should have(1).items }

    context "content" do
      subject { importer.invalid.first }
      it { should have_key(:original_row) }
      it { should have_key(:attributes) }
      it { should have_key(:model) }
    end
    context "model" do
      subject { importer.invalid.first[:model] }
      it      { should be_a(Student) }
      it      { should_not be_valid }
      it      { should have(1).error_on(:personal_id) }
    end
  end

  describe ".import!" do
    let(:csv) {
      <<-CSV.strip_heredoc
      School1 , Grade1 , 20000101-1234 , Lastname , Firstname , Flicka 
      School1 , Grade1 , 20000101-1235 , Lastname , Firstname , Pojke 
      CSV
    }

    it "saves students in a group hierarchy" do
      expect(Group.count).to   eq 0
      expect(Student.count).to eq 0

      importer.import!

      expect(Group.count).to   eq 2
      expect(Student.count).to eq 2

      girl = Student.where(personal_id: "20000101-1234").first

      expect(girl.instance).to    eq instance
      expect(girl.personal_id).to eq "20000101-1234"
      expect(girl.first_name).to  eq "Firstname"
      expect(girl.last_name).to   eq "Lastname"
      expect(girl.gender).to      eq "female"

      boy = Student.where(personal_id: "20000101-1235").first

      expect(boy.instance).to    eq instance
      expect(boy.personal_id).to eq "20000101-1235"
      expect(boy.first_name).to  eq "Firstname"
      expect(boy.last_name).to   eq "Lastname"
      expect(boy.gender).to      eq "male"

      school = Group.where(name: "School1").first

      expect(school.imported).to be_true
      expect(school.instance).to eq instance
      expect(school.name).to     eq "School1"
      expect(school.students).to include(girl)
      expect(school.students).to include(boy)

      grade = Group.where(name: "Grade1").first

      expect(grade.imported).to be_true
      expect(grade.instance).to eq instance
      expect(grade.name).to     eq "Grade1"
      expect(grade.parent).to   eq school
      expect(grade.students).to include(girl)
      expect(grade.students).to include(boy)
    end

    context "without a grade" do
      let(:csv) {
        <<-CSV.strip_heredoc
        School1 ,, 20000101-1234 , Lastname , Firstname , Flicka 
        CSV
      }

      it "does not create a grade group" do
        expect(Group.count).to                eq 0
        importer.import!
        expect(Group.count).to                eq 1
        expect(Group.first.students.count).to eq 1
      end
    end

    context "without grade and school" do
      let(:csv) {
        <<-CSV.strip_heredoc
        ,, 20000101-1234 , Lastname , Firstname , Flicka 
        CSV
      }

      it "does not create a grade group" do
        expect(Group.count).to eq 0
        importer.import!
        expect(Group.count).to eq 0
      end
    end
  end
end
