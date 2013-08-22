require 'spec_helper'

describe EvaluationsHelper do
  describe "#working_with_evaluation_template?" do
    let(:params)     { { "controller" => "evaluations" } }
    let(:evaluation) { nil }
    before(:each)    { helper.stub(:params).and_return(params) }

    subject { helper.working_with_evaluation_template?(evaluation) }

    it { should be_false }

    context "under templates/evaluation controller" do
      let(:params) { { "controller" => "template/evaluations" } }
      it           { should be_true }
    end
    context "with a suite evaluation" do
      let(:evaluation) { create(:suite_evaluation) }
      it               { should be_false }
    end
    context "with an evaluation template" do
      let(:evaluation) { create(:evaluation_template) }
      it               { should be_true }
    end
  end
  describe "#working_with_generic_evaluation?" do
    let(:params)     { { "controller" => "evaluations" } }
    let(:evaluation) { nil }
    before(:each)    { helper.stub(:params).and_return(params) }

    subject { helper.working_with_generic_evaluation?(evaluation) }

    it { should be_false }

    context "under generic/evaluation controller" do
      let(:params) { { "controller" => "generic/evaluations" } }
      it           { should be_true }
    end
    context "with a suite evaluation" do
      let(:evaluation) { create(:suite_evaluation) }
      it               { should be_false }
    end
    context "with a generic evaluation" do
      let(:evaluation) { create(:generic_evaluation) }
      it               { should be_true }
    end
  end

  describe "#evaluation_cancel_path" do
    let(:evaluation) { nil }
    subject          { helper.evaluation_cancel_path(evaluation) }
    it               { should be_blank }

    context "with unsaved record" do
      context "with a suite evaluation" do
        let(:evaluation) { build(:suite_evaluation) }
        it { should == helper.suite_path(evaluation.suite) }
      end
      context "with an evaluation template" do
        let(:evaluation) { build(:evaluation_template) }
        it { should == helper.template_evaluations_path() }
      end
      context "with a generic evaluation" do
        let(:evaluation) { build(:generic_evaluation) }
        it { should == helper.generic_evaluations_path() }
      end
    end
    context "with saved record" do
      context "with a suite evaluation" do
        let(:evaluation) { build(:suite_evaluation) }
        it { should == helper.suite_path(evaluation.suite) }
      end
      context "with an evaluation template" do
        let(:evaluation) { create(:evaluation_template) }
        it { should == helper.evaluation_path(evaluation) }
      end
      context "with a generic evaluation" do
        let(:evaluation) { create(:generic_evaluation) }
        it { should == helper.evaluation_path(evaluation) }
      end
    end
  end

  describe "#evaluation_progress_bar" do
    let(:suite)        { create(:suite) }
    let(:evaluation)   { create(:suite_evaluation, suite: suite, max_result: 10, _yellow: 4..7) }
    let(:participants) { create_list(:participant, 5, suite: suite) }

    subject { Capybara::Node::Simple.new(helper.evaluation_progress_bar(evaluation)) }

    context "with no results" do
      it { should     have_selector(".progress.evaluation-status-progress") }
      it { should_not have_selector(".progress .bar") }
    end

    context "with all results" do
      before(:each) do
        create(:result, student: participants[0].student, evaluation: evaluation, value: 1) # red
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
        create(:result, student: participants[3].student, evaluation: evaluation, value: 8) # green
      end

      it { should have_selector(".progress.evaluation-status-progress") }
      it { should have_selector(".progress .bar", count: 4) }
      it { should have_selector(".progress .bar-success[style=\"width: 20.0%\"]") }
      it { should have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]") }
      it { should have_selector(".progress .bar-danger[style=\"width: 20.0%\"]") }
      it { should have_selector(".progress .bar-disabled[style=\"width: 0.0%\"]") }
    end
    context "with colors missing" do
      before(:each) do
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
      end

      it { should have_selector(".progress.evaluation-status-progress") }
      it { should have_selector(".progress .bar", count: 4) }
      it { should have_selector(".progress .bar-success[style=\"width: 0.0%\"]") }
      it { should have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]") }
      it { should have_selector(".progress .bar-danger[style=\"width: 0.0%\"]") }
      it { should have_selector(".progress .bar-disabled[style=\"width: 0.0%\"]") }
    end
    context "with absent results" do
      before(:each) do
        create(:result, student: participants[0].student, evaluation: evaluation, value: 1) # red
        create(:result, student: participants[1].student, evaluation: evaluation, value: 5) # yellow
        create(:result, student: participants[2].student, evaluation: evaluation, value: 6) # yellow
        create(:result, student: participants[3].student, evaluation: evaluation, value: 8) # green
        create(:result, student: participants[4].student, evaluation: evaluation, value: nil, absent: true) # absent
      end

      it { should have_selector(".progress.evaluation-status-progress") }
      it { should have_selector(".progress .bar", count: 4) }
      it { should have_selector(".progress .bar-success[style=\"width: 20.0%\"]") }
      it { should have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]") }
      it { should have_selector(".progress .bar-danger[style=\"width: 20.0%\"]") }
      it { should have_selector(".progress .bar-disabled[style=\"width: 20.0%\"]") }
    end
  end
end
