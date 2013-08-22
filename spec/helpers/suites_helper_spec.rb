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

    let(:evaluation) { create(:evaluation, max_result: 20, _yellow: 10..15) }

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
      context "for absent result" do
        let(:result) { create(:result, value: 18, evaluation: evaluation, absent: true) }
        it "returns a blank string" do
          helper.result_color_class(result).should be_blank
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
  describe ".result_color_image" do
    it "handles nil results" do
      helper.result_color_image(nil).should be_blank
    end

    let(:evaluation) { create(:evaluation, max_result: 20, _yellow: 10..15) }

    context "with result object" do
      let(:value)  { nil }
      let(:result) { create(:result, value: value, evaluation: evaluation) }
      subject      { Capybara::Node::Simple.new(helper.result_color_image(result)) }

      context "for red result" do
        let(:value) { 5 }
        it { should have_selector("img") }
        it { should have_selector("img[src$='red.png']") }
        it { should have_selector("img[alt='Red']") }
      end
      context "for yellow result" do
        let(:value) { 12 }
        it { should have_selector("img") }
        it { should have_selector("img[src$='yellow.png']") }
        it { should have_selector("img[alt='Yellow']") }
      end
      context "for green result" do
        let(:value) { 18 }
        it { should have_selector("img") }
        it { should have_selector("img[src$='green.png']") }
        it { should have_selector("img[alt='Green']") }
      end
      context "for absent result" do
        let(:result) { create(:result, value: 18, evaluation: evaluation, absent: true) }
        subject      { helper.result_color_image(result) }

        it { should be_blank }
      end
    end
    context "value and evaluation" do
      let(:value) { nil }
      subject     { Capybara::Node::Simple.new(helper.result_color_image(value, evaluation)) }

      context "for red result" do
        let(:value) { 5 }
        it { should have_selector("img") }
        it { should have_selector("img[src$='red.png']") }
        it { should have_selector("img[alt='Red']") }
      end
      context "for yellow result" do
        let(:value) { 12 }
        it { should have_selector("img") }
        it { should have_selector("img[src$='yellow.png']") }
        it { should have_selector("img[alt='Yellow']") }
      end
      context "for green result" do
        let(:value) { 18 }
        it { should have_selector("img") }
        it { should have_selector("img[src$='green.png']") }
        it { should have_selector("img[alt='Green']") }
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
    it "handles single value ranges" do
      helper.format_range(10..10).should == 10
    end
  end
end
