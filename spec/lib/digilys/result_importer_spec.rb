require 'spec_helper'
require 'digilys/result_importer'

describe Digilys::ResultImporter do
  let(:csv)             { "" }
  let(:instance)        { create(:instance) }
  let(:evaluation)      { create(:evaluation) }
  let(:has_header_row)  { false }

  let(:student)            { create(:student, personal_id: "20001212-0000") }
  let(:first_student)      { create(:student, personal_id: "20000101-1234") }
  let(:second_student)     { create(:student, personal_id: "20000202-1234") }

  let(:suite)                       { create(:suite) }
  let(:suite_without_participants)  { create(:suite) }

  let(:first_participant)  { create(:participant, student: first_student, suite: suite) }
  let(:second_participant)  { create(:participant, student: second_student, suite: suite) }

  let(:evaluation)   {
    create(
      :suite_evaluation,
      suite: suite_without_participants,
      max_result: 10,
      _yellow: 4..7,
      evaluation_participants: [first_participant, second_participant]
    )
  }
  let(:particiapnts) { create_list(:participant, 2, suite: evaluation.suite, evaluation: evaluation) }

  let(:evaluation_without_participants)   {
    create(
      :suite_evaluation,
      suite: suite_without_participants,
      max_result: 10,
      _yellow: 4..7,
      evaluation_participants: []
    )
  }

  subject(:importer)    { Digilys::ResultImporter.new(CSV.new(csv), evaluation.id, has_header_row) }

  describe ".parsed_attributes" do
    let(:csv) {
      <<-CSV.strip_heredoc
      20000101-1234,5
      20000202-1234,7
      CSV
    }

    subject(:parsed_attributes) { importer.parsed_attributes }

    it { should have(2).items }

    context "original row" do
      subject { parsed_attributes.first[:original_row] }
      it { should == %w(20000101-1234 5) }
    end
    context "attributes" do
      subject { parsed_attributes.first[:attributes] }

      its(:keys) { should have(2).items }

      it { should include(personal_id: "20000101-1234") }
      it { should include(result: "5") }
    end

    context "with spaces" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20000101-1234, 10
        CSV
      }
      subject { parsed_attributes.first[:attributes] }
      it { should include(personal_id: "20000101-1234") }
      it { should include(result: "10") }
    end
  end

  describe ".valid?" do
    before(:each) do
      importer.valid?
    end
    context "with valid rows" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20000101-1234,5
        20000202-1234,7
        CSV
      }

      it { should be_valid }
      its(:valid_count)             { should == 2 }
      its(:invalid_results_count)   { should == 0 }
      its(:invalid_students_count)  { should == 0 }
    end

    context "with invalid rows" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20000101-1234,5
        20000202-1234,
        CSV
      }

      it { should_not be_valid }
      its(:valid_count)             { should == 1 }
      its(:invalid_results_count)   { should == 1 }
      its(:invalid_students_count)  { should == 0 }
    end
    context "with student not being participant" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20001212-0000,5
        CSV
      }

      it { should_not be_valid }

      its(:valid_count)             { should == 0 }
      its(:invalid_results_count)   { should == 0 }
      its(:invalid_students_count)  { should == 1 }
    end
    context "with missing student" do
      let(:csv) {
        <<-CSV.strip_heredoc
        11110000-0000,5
        CSV
      }

      it { should_not be_valid }

      its(:valid_count)             { should == 0 }
      its(:invalid_results_count)   { should == 0 }
      its(:invalid_students_count)  { should == 1 }
    end
    context "with invalid result" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20000101-1234,50
        CSV
      }

      it { should_not be_valid }
      its(:valid_count)             { should == 0 }
      its(:invalid_results_count)   { should == 1 }
      its(:invalid_students_count)  { should == 0 }
    end
    context "with negative result" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20000101-1234,-1
        CSV
      }

      it { should_not be_valid }
      its(:valid_count)             { should == 0 }
      its(:invalid_results_count)   { should == 1 }
      its(:invalid_students_count)  { should == 0 }
    end
    context "with no participants" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20000101-1234,5
        CSV
      }

      subject(:importer) { Digilys::ResultImporter.new(CSV.new(csv), evaluation_without_participants.id) }

      it { should_not be_valid }

      its(:valid_count)             { should == 0 }
      its(:invalid_results_count)   { should == 0 }
      its(:invalid_students_count)  { should == 1 }
    end
  end

  describe ".import!" do
    let(:update_existing) { true }
    let(:csv) {
      <<-CSV.strip_heredoc
      20000101-1234,7
      20000202-1234,4
      CSV
    }

    it "saves results" do
      expect(Result.count).to eq 0

      importer.import!

      expect(Result.count).to eq 2

      # First
      r = Result.where(student_id: first_student.id).first

      expect(r.evaluation_id).to eq evaluation.id
      expect(r.student_id).to    eq first_student.id
      expect(r.value).to         eq 7
      expect(r.absent).to        be_false

      # Second
      r = Result.where(student_id: second_student.id).first

      expect(r.evaluation_id).to eq evaluation.id
      expect(r.student_id).to    eq second_student.id
      expect(r.value).to         eq 4
      expect(r.absent).to        be_false
    end

    context "with existing" do
      let(:csv) {
        <<-CSV.strip_heredoc
        20000101-1234,1
        CSV
      }

      before(:each) do
        create(
          :result,
          student:      first_student,
          evaluation:      evaluation,
          value:           5
        )
      end

      it "saves updates value" do
        expect(Result.count).to eq 1

        importer.import!

        expect(Result.count).to eq 1

        r = Result.where(student_id: first_student.id).first

        expect(r.evaluation_id).to eq evaluation.id
        expect(r.student_id).to    eq first_student.id
        expect(r.value).to         eq 1
        expect(r.absent).to        be_false
      end
    end
  end
end
