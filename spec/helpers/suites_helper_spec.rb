require 'spec_helper'

describe SuitesHelper do
  context "#calendar_entries" do
    let(:suite) { create(:suite) }
    subject { helper.calendar_entries(suite) }

    context "without entites" do
      it { should be_empty }
    end

    context "with entities" do
      let(:entities) do
        [
          create(:suite_evaluation, suite: suite, date: Date.yesterday), 
          create(:suite_evaluation, suite: suite, date: Date.today), 
          create(:suite_evaluation, suite: suite, date: Date.tomorrow), 
          create(:meeting,          suite: suite, date: Date.yesterday), 
          create(:meeting,          suite: suite, date: Date.today), 
          create(:meeting,          suite: suite, date: Date.tomorrow)
        ]
      end

      it { should match_array(entities) }

      it "sorts the collection by the entities's date" do
        prev = nil
        subject.each do |e|
          e.date.should >= prev.date unless prev.nil?
          prev = e
        end
      end
    end
  end

  context "#working_with_suite?" do
    let(:params)     { {} }
    let(:suite)      { nil }
    let(:evaluation) { nil }
    before(:each)    { helper.stub(:params).and_return(params) }

    subject { helper.working_with_suite?(suite, evaluation) }

    it { should be_false }

    context "with a regular suite" do
      let(:suite) { create(:suite, is_template: false) }
      it          { should be_true }
    end
    context "with a template suite" do
      let(:suite) { create(:suite, is_template: true) }
      it          { should be_false }
    end
    context "under suites#index" do
      let(:params) { { "controller" => "suites", "action" => "index" } }
      it           { should be_true }
    end
    context "with suite_id" do
      let(:params) { { "controller" => "evaluations", "action" => "new", suite_id: 1 } }
      it           { should be_true }
    end
    context "with suite_id and students controller" do
      let(:params) { { "controller" => "students", "action" => "show", suite_id: 1 } }
      it           { should be_false }
    end
    context "with an evaluation assigned to a suite" do
      let(:evaluation) { create(:suite_evaluation) }
      it               { should be_true }
    end
    context "under suites controller with a suite template" do
      let(:params) { { "controller" => "suites" } }
      let(:suite)  { create(:suite, is_template: true) }
      it           { should be_false }
    end
  end

  context "#working_with_suite_template?" do
    let(:params)  { {} }
    let(:suite)   { nil }
    before(:each) { helper.stub(:params).and_return(params) }

    subject { helper.working_with_suite_template?(suite) }

    it { should be_false }

    context "with a regular suite" do
      let(:suite) { create(:suite, is_template: false) }
      it          { should be_false }
    end
    context "with a template suite" do
      let(:suite) { create(:suite, is_template: true) }
      it          { should be_true }
    end
    context "under suites#template" do
      let(:params) { { "controller" => "template/suites" } }
      it           { should be_true }
    end
  end

  describe ".result_color_class" do
    it "handles nil results" do
      helper.result_color_class(nil).should be_blank
    end

    let(:evaluation) { create(:evaluation, max_result: 20, red_below: 10, green_above: 15) }

    context "with result object" do
      context "for red result" do
        let(:result) { create(:result, value: 5, evaluation: evaluation) }
        it "returns red" do
          helper.result_color_class(result).should == "result-red"
        end
      end
      context "for yellow result" do
        let(:result) { create(:result, value: 12, evaluation: evaluation) }
        it "returns yellow" do
          helper.result_color_class(result).should == "result-yellow"
        end
      end
      context "for green result" do
        let(:result) { create(:result, value: 18, evaluation: evaluation) }
        it "returns green" do
          helper.result_color_class(result).should == "result-green"
        end
      end
    end
    context "value and evaluation" do
      context "for red result" do
        it "returns red" do
          helper.result_color_class(5, evaluation).should == "result-red"
        end
      end
      context "for yellow result" do
        it "returns yellow" do
          helper.result_color_class(12, evaluation).should == "result-yellow"
        end
      end
      context "for green result" do
        it "returns green" do
          helper.result_color_class(18, evaluation).should == "result-green"
        end
      end
    end
  end

  describe ".format_range" do
    it "joins ranges with a html ndash" do
      helper.format_range(10..20).should == "10 &ndash; 20"
    end
    it "handles single values" do
      helper.format_range(10).should == 10
    end
  end
end
