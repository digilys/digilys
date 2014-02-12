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
      Group.count.should   == 0
      Student.count.should == 0

      importer.import!

      Group.count.should   == 2
      Student.count.should == 2

      girl = Student.where(personal_id: "20000101-1234").first

      girl.instance.should    == instance
      girl.personal_id.should == "20000101-1234"
      girl.first_name.should  == "Firstname"
      girl.last_name.should   == "Lastname"
      girl.gender.should      == "female"

      boy = Student.where(personal_id: "20000101-1235").first

      boy.instance.should    == instance
      boy.personal_id.should == "20000101-1235"
      boy.first_name.should  == "Firstname"
      boy.last_name.should   == "Lastname"
      boy.gender.should      == "male"

      school = Group.where(name: "School1").first

      school.imported.should be_true
      school.instance.should == instance
      school.name.should     == "School1"
      school.students.should include(girl)
      school.students.should include(boy)

      grade = Group.where(name: "Grade1").first

      grade.imported.should be_true
      grade.instance.should == instance
      grade.name.should     == "Grade1"
      grade.parent.should   == school
      grade.students.should include(girl)
      grade.students.should include(boy)
    end

    context "without a grade" do
      let(:csv) {
        <<-CSV.strip_heredoc
        School1 ,, 20000101-1234 , Lastname , Firstname , Flicka 
        CSV
      }

      it "does not create a grade group" do
        Group.count.should                == 0
        importer.import!
        Group.count.should                == 1
        Group.first.students.count.should == 1
      end
    end

    context "without grade and school" do
      let(:csv) {
        <<-CSV.strip_heredoc
        ,, 20000101-1234 , Lastname , Firstname , Flicka 
        CSV
      }

      it "does not create a grade group" do
        Group.count.should   == 0
        importer.import!
        Group.count.should   == 0
      end
    end
  end
end
