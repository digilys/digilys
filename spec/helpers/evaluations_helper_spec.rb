require 'spec_helper'

describe EvaluationsHelper do
  describe "#evaluation_progress_bar" do
    let(:suite)        { create(:suite) }
    let(:evaluation)   { create(:suite_evaluation, suite: suite, max_result: 10, red_below: 4, green_above: 7) }
    let(:participants) { create_list(:participant, 5, suite: suite) }

    subject { Capybara::Node::Simple.new(helper.evaluation_progress_bar(evaluation)) }

    context "with no results" do
      it { should     have_selector(".progress") }
      it { should_not have_selector(".progress .bar") }
    end

    context "with all results" do
      before(:each) do
        create(:result, student: participants[0].student, evaluation: evaluation, value: 1) # red
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
        create(:result, student: participants[3].student, evaluation: evaluation, value: 8) # green
      end

      it { should have_selector(".progress") }
      it { should have_selector(".progress .bar", count: 3) }
      it { should have_selector(".progress .bar-success[style=\"width: 20.0%\"]") }
      it { should have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]") }
      it { should have_selector(".progress .bar-danger[style=\"width: 20.0%\"]") }
    end
    context "with colors missing" do
      before(:each) do
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
      end

      it { should have_selector(".progress") }
      it { should have_selector(".progress .bar", count: 3) }
      it { should have_selector(".progress .bar-success[style=\"width: 0.0%\"]") }
      it { should have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]") }
      it { should have_selector(".progress .bar-danger[style=\"width: 0.0%\"]") }
    end
  end
end
