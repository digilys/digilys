require 'spec_helper'

describe VisualizationsController do
  describe "#results_to_datatable" do
    let!(:suite)        { create(:suite) }
    let!(:students)     { create_list(:student, 2) }
    let!(:participants) { students.collect { |s| create(:participant, suite: suite, student: s) } }
    let!(:evaluations)  { create_list(:suite_evaluation, 2, suite: suite, max_result: 10, red_below: 4, green_above: 7) }
    let!(:result_s1_e1) { create(:result, evaluation: evaluations.first,  student: students.first,  value: 4) }
    let!(:result_s1_e2) { create(:result, evaluation: evaluations.second, student: students.first,  value: 5) }
    let!(:result_s2_e1) { create(:result, evaluation: evaluations.first,  student: students.second, value: 6) }
    let!(:result_s2_e2) { create(:result, evaluation: evaluations.second, student: students.second, value: 7) }

    subject(:table) { controller.send(:results_to_datatable, evaluations) }

    it { should have(3).items }

    context "title row" do
      subject { table.first }
      it { should have(3).items }
      its(:first)  { should == Evaluation.model_name.human(count: 2) }
      its(:second) { should == students.first.name }
      its(:third)  { should == students.second.name }
    end

    context "row for evaluation 1" do
      subject { table.second }
      it { should have(3).items }
      its(:first)  { should == evaluations.first.name }
      its(:second) { should == result_s1_e1.value }
      its(:third)  { should == result_s2_e1.value }
    end

    context "row for evaluation 2" do
      subject { table.third }
      it { should have(3).items }
      its(:first)  { should == evaluations.second.name }
      its(:second) { should == result_s1_e2.value }
      its(:third)  { should == result_s2_e2.value }
    end
  end

  describe "#result_colors_to_datatable" do
    let!(:suite)        { create(:suite) }
    let!(:students)     { create_list(:student, 2) }
    let!(:participants) { students.collect { |s| create(:participant, suite: suite, student: s) } }
    let!(:evaluations)  { create_list(:suite_evaluation, 3, suite: suite, max_result: 10, red_below: 4, green_above: 7) }
    let!(:result_s1_e1) { create(:result, evaluation: evaluations.first,  student: students.first,  value: 3) }
    let!(:result_s1_e2) { create(:result, evaluation: evaluations.second, student: students.first,  value: 5) }
    let!(:result_s2_e1) { create(:result, evaluation: evaluations.first,  student: students.second, value: 6) }
    let!(:result_s2_e2) { create(:result, evaluation: evaluations.second, student: students.second, value: 8) }

    subject(:table) { controller.send(:result_colors_to_datatable, evaluations) }

    it { should have(4).items }

    context "title row" do
      subject      { table.first }
      it           { should have(4).items }
      its(:first)  { should == Evaluation.model_name.human(count: 2) }
      its(:second) { should == I18n.t(:red) }
      its(:third)  { should == I18n.t(:yellow) }
      its(:fourth) { should == I18n.t(:green) }
    end

    context "row for evaluation 1" do
      subject      { table.second }
      it           { should have(4).items }
      its(:first)  { should == evaluations.first.name }
      its(:second) { should == evaluations.first.result_distribution[:red] }
      its(:third)  { should == evaluations.first.result_distribution[:yellow] }
      its(:fourth) { should == evaluations.first.result_distribution[:green] }
    end
    context "row for evaluation 2" do
      subject      { table.third }
      it           { should have(4).items }
      its(:first)  { should == evaluations.second.name }
      its(:second) { should == evaluations.second.result_distribution[:red] }
      its(:third)  { should == evaluations.second.result_distribution[:yellow] }
      its(:fourth) { should == evaluations.second.result_distribution[:green] }
    end
    context "row for evaluation 3" do
      subject      { table.fourth }
      it           { should have(4).items }
      its(:first)  { should == evaluations.third.name }
      its(:second) { should == 0 }
      its(:third)  { should == 0 }
      its(:fourth) { should == 0 }
    end
  end
end
