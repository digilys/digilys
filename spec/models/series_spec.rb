require 'spec_helper'

describe Series do
  context "factories" do
    context "default" do
      subject { build(:series) }
      it      { should be_valid }
    end
    context "invalid" do
      subject { build(:invalid_series) }
      it      { should_not be_valid }
    end
  end
  context "accessible attributes" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:suite) }
    it { should allow_mass_assignment_of(:suite_id) }
  end
  context "validation" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:suite_id) }
  end


  describe ".update_current!" do
    let(:series) { create(:series) }

    def create_evaluation(status, date, is_series_current = false)
      create(
        :suite_evaluation,
        suite:             series.suite,
        series:            series,
        status:            status,
        date:              date,
        is_series_current: is_series_current
      )
    end

    it "changes the series current to the latest evaluation which is not empty" do
      previous_current = create_evaluation(:partial, Date.yesterday, true)
      new_current      = create_evaluation(:partial, Date.today,     false)

      series.update_current!

      new_current.reload.is_series_current.should be_true
      previous_current.reload.is_series_current.should be_false
    end

    it "handles when all evaluations are empty" do
      create_evaluation(:empty, Date.today)
      series.update_current!
      series.evaluations(true).collect(&:is_series_current).should_not include(true)
    end
  end

  describe ".current_evaluation" do
    def build_evaluation(status, date)
      create(:suite_evaluation, series: series, suite: series.suite, status: status, date: date)
    end

    let(:series) { create(:series) }

    it "returns the evaluation with the latest date" do
      expected = build_evaluation(:complete, Date.today)
      build_evaluation(:complete, Date.yesterday)
      series.current_evaluation.should == expected
    end
    it "does not return empty evaluations" do
      expected = build_evaluation(:complete, Date.yesterday)
      build_evaluation(:empty, Date.today)
      series.current_evaluation.should == expected
    end
    it "returns partial or complete evaluations" do
      expected = build_evaluation(:partial, Date.today)
      build_evaluation(:complete, Date.yesterday)
      series.current_evaluation.should == expected

      expected = build_evaluation(:complete, Date.tomorrow)
      series.current_evaluation.should == expected
    end
  end

  describe ".destroy_on_empty!" do
    let(:series) { create(:series) }
    let(:evaluation) { create(:suite_evaluation, suite: series.suite, series: series) }

    it "destroys the series if it has no evaluations" do
      series.destroy_on_empty!
      series.should be_destroyed
    end
    it "does nothing if the series has evaluations" do
      evaluation
      series.destroy_on_empty!
      series.should_not be_destroyed
    end
  end


  describe ".result_for" do
    let(:series)      { create(:series) }
    let(:suite)       { series.suite }

    let(:evaluation1) { create(:suite_evaluation, suite: suite, series: series, date: Date.today) }
    let(:evaluation2) { create(:suite_evaluation, suite: suite, series: series, date: Date.today + 1) }
    let(:evaluation3) { create(:suite_evaluation, suite: suite, series: series, date: Date.today + 2) }

    let(:student)     { create(:student) }

    let!(:result1)    { create(:result, evaluation: evaluation1, student: student, value: 1) }
    let!(:result2)    { create(:result, evaluation: evaluation2, student: student, value: nil, absent: true) }
    let!(:result3)    { create(:result, evaluation: evaluation3, value: 1) } # Other student

    it "returns the newest non-absent result from the evaluations in the series" do
      evaluation3.reload.is_series_current.should be_true

      # result2 is absent, no result for the student in evaluation 3
      series.result_for(student).should == result1
    end
  end
end
