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

    subject(:output)   { Capybara::Node::Simple.new(helper.evaluation_progress_bar(evaluation)) }

    def create_result(participant_index, value)
      create(:result,
        student: participants[participant_index].student,
        evaluation: evaluation,
        value: value,
        absent: value.nil?
      )
    end

    it "has no bars when there is no result" do
      expect(output).to     have_selector(".progress.evaluation-status-progress")
      expect(output).not_to have_selector(".progress .bar")
    end
    it "has a bar for each type of result" do
      create_result(0, 1) # red
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow
      create_result(3, 8) # green

      expect(output).to have_selector(".progress.evaluation-status-progress")
      expect(output).to have_selector(".progress .bar", count: 4)
      expect(output).to have_selector(".progress .bar-success[style=\"width: 20.0%\"]")
      expect(output).to have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]")
      expect(output).to have_selector(".progress .bar-danger[style=\"width: 20.0%\"]")
      expect(output).to have_selector(".progress .bar-disabled[style=\"width: 0.0%\"]")
    end
    it "has zero percent width bars for missing types" do
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow

      expect(output).to have_selector(".progress.evaluation-status-progress")
      expect(output).to have_selector(".progress .bar", count: 4)
      expect(output).to have_selector(".progress .bar-success[style=\"width: 0.0%\"]")
      expect(output).to have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]")
      expect(output).to have_selector(".progress .bar-danger[style=\"width: 0.0%\"]")
      expect(output).to have_selector(".progress .bar-disabled[style=\"width: 0.0%\"]")
    end
    it "adds a disabled bar for absent results" do
      create_result(0, 1) # red
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow
      create_result(3, 8) # green
      create_result(4, nil) # absent

      expect(output).to have_selector(".progress.evaluation-status-progress")
      expect(output).to have_selector(".progress .bar", count: 4)
      expect(output).to have_selector(".progress .bar-success[style=\"width: 20.0%\"]")
      expect(output).to have_selector(".progress .bar-yellow[style=\"width: 40.0%\"]")
      expect(output).to have_selector(".progress .bar-danger[style=\"width: 20.0%\"]")
      expect(output).to have_selector(".progress .bar-disabled[style=\"width: 20.0%\"]")
    end

    it "includes percentages in the title" do
      create_result(0, 1) # red
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow
      create_result(3, 8) # green
      create_result(4, nil) # absent

      expect(output.find(".evaluation-status-progress[title]")["title"]).to eq(
        "#{t(:red)}: 20%<br>#{t(:yellow)}: 40%<br>#{t(:green)}: 20%<br>#{t(:absent)}: 20%"
      )
    end

    context "rounding" do
      let(:participants) { create_list(:participant, 7, suite: suite) }
      
      it "rounds percentages down" do
        create_result(0, 1) # red
        create_result(1, 1) # red
        create_result(2, 6) # yellow
        create_result(3, 6) # yellow
        create_result(4, 6) # yellow
        create_result(5, 6) # yellow
        create_result(6, 6) # yellow

        expect(output).to have_selector(".progress.evaluation-status-progress")
        expect(output).to have_selector(".progress .bar", count: 4)
        expect(output).to have_selector(".progress .bar-success[style=\"width: 0.0%\"]")
        expect(output).to have_selector(".progress .bar-yellow[style=\"width: 71.4%\"]") # 5.0/7.0 = 0.71428...
        expect(output).to have_selector(".progress .bar-danger[style=\"width: 28.5%\"]") # 2.0/7.0 = 0.28571...
        expect(output).to have_selector(".progress .bar-disabled[style=\"width: 0.0%\"]")
      end
    end
  end

  describe "#evaluation_info" do
    let(:suite)        { create(:suite) }
    let(:evaluation)   { create(:suite_evaluation, suite: suite, max_result: 10, _yellow: 4..7) }
    let(:participants) { create_list(:participant, 5, suite: suite) }

    subject(:output)   { helper.evaluation_info(evaluation) }

    def create_result(participant_index, value)
      create(:result,
        student: participants[participant_index].student,
        evaluation: evaluation,
        value: value,
        absent: value.nil?
      )
    end

    before(:each) do
      create_result(0, 1) # red
      create_result(1, 5) # yellow
      create_result(2, 6) # yellow
      create_result(3, 8) # green
      create_result(4, nil) # absent
    end

    it "includes percentages by color" do
      expect(output).to include(
        "#{t(:red)}: 20%<br>#{t(:yellow)}: 40%<br>#{t(:green)}: 20%<br>#{t(:absent)}: 20%"
      )
    end
    it "includes the evaluation's date" do
      expect(output).to include("<strong class=\"date\">#{evaluation.date}</strong>")
    end
    it "includes an overdue class for overdue evaluations" do
      evaluation.status = :partial
      evaluation.date = Date.yesterday
      output = helper.evaluation_info(evaluation)
      expect(output).to include("<strong class=\"date overdue\">#{evaluation.date}</strong>")
    end
    it "outputs nothing if the evaluation is not a suite evaluation" do
      expect(helper.evaluation_info(create(:evaluation_template))).to be_nil
    end

    it "handles evaluations without results" do
      evaluation = create(:suite_evaluation)
      expect(helper.evaluation_info(evaluation)).not_to include("%")
    end
  end
end
