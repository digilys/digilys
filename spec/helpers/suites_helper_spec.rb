require 'spec_helper'

describe SuitesHelper do
  context "#calendar_entries" do
    let(:suite)       { create(:suite) }
    subject(:entries) { helper.calendar_entries(suite) }

    context "without entites" do
      it { should include(open: [], closed: []) }
    end

    context "with entities" do
      let!(:open) do
        [
          create(:suite_evaluation, suite: suite, date: Date.today,    status:    :empty, position: 1),
          create(:suite_evaluation, suite: suite, date: Date.tomorrow, status:    :partial, position: 2),
          create(:meeting,          suite: suite, date: Date.today,    completed: false),
          create(:meeting,          suite: suite, date: Date.tomorrow, completed: false)
        ]
      end
      let!(:closed) do
        [
          create(:suite_evaluation, suite: suite, date: Date.yesterday,         status:    :complete, position: 1),
          create(:meeting,          suite: suite, date: Date.yesterday - 1.day, completed: true)
        ]
      end

      it "partitions the entities by open/closed and sorts evaluations by position and meetings by date" do
        expect(entries[:open]).to   match_array(open)
        expect(entries[:closed]).to match_array(closed)

        entries.each_value do |coll|
          prev = nil
          coll.each do |e|
            expect(e.date).to be >= prev.date unless prev.nil?
            prev = e
          end
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
    let(:evaluation) { nil }
    before(:each) { helper.stub(:params).and_return(params) }

    subject { helper.working_with_suite_template?(suite, evaluation) }

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
    context "with suite evaluation" do
      let(:suite)       { create(:suite, is_template: true) }
      let(:evaluation)  { create(:suite_evaluation, suite: suite) }
      it                { should be_true }
    end
  end

  describe ".result_color_class" do
    it "handles nil results" do
      expect(helper.result_color_class(nil)).to be_blank
    end

    let(:evaluation) { create(:evaluation, max_result: 20, _yellow: 10..15) }

    context "with result object" do
      context "for red result" do
        let(:result) { create(:result, value: 5, evaluation: evaluation) }
        it "returns red" do
          expect(helper.result_color_class(result)).to eq "result-red"
        end
      end
      context "for yellow result" do
        let(:result) { create(:result, value: 12, evaluation: evaluation) }
        it "returns yellow" do
          expect(helper.result_color_class(result)).to eq "result-yellow"
        end
      end
      context "for green result" do
        let(:result) { create(:result, value: 18, evaluation: evaluation) }
        it "returns green" do
          expect(helper.result_color_class(result)).to eq "result-green"
        end
      end
      context "for absent result" do
        let(:result) { create(:result, value: 18, evaluation: evaluation, absent: true) }
        it "returns a blank string" do
          expect(helper.result_color_class(result)).to be_blank
        end
      end
    end
    context "value and evaluation" do
      context "for red result" do
        it "returns red" do
          expect(helper.result_color_class(5, evaluation)).to eq "result-red"
        end
      end
      context "for yellow result" do
        it "returns yellow" do
          expect(helper.result_color_class(12, evaluation)).to eq "result-yellow"
        end
      end
      context "for green result" do
        it "returns green" do
          expect(helper.result_color_class(18, evaluation)).to eq "result-green"
        end
      end
    end
  end

  describe ".format_range" do
    it "joins ranges with a html ndash" do
      expect(helper.format_range(10..20)).to eq "10 &ndash; 20"
    end
    it "handles single values" do
      expect(helper.format_range(10)).to eq 10
    end
    it "handles single value ranges" do
      expect(helper.format_range(10..10)).to eq 10
    end
  end

  describe ".closed_suite_message" do
    let(:can_change) { true }
    let(:suite)      { build(:suite, status: :closed, id: -1) }
    let(:result)     { helper.closed_suite_message(suite) }
    subject(:html)   { Capybara::Node::Simple.new(result) }

    before(:each)    { helper.stub(:can?).and_return(can_change) }

    it { should have_selector(".alert.alert-block.alert-warning p", count: 2) }
    it { should have_selector("p a[href='#{confirm_status_change_suite_path(suite)}']") }

    context "with an open suite" do
      let(:suite) { build(:suite, status: :open) }
      subject     { result }
      it          { should be_nil }
    end
    context "without a suite" do
      let(:suite) { nil }
      subject     { result }
      it          { should be_nil }
    end
    context "with an unprivileged user" do
      let(:can_change) { false }
      it               { should     have_selector(".alert.alert-block.alert-warning p", count: 1) }
      it               { should_not have_selector("p a") }
    end
  end
end
