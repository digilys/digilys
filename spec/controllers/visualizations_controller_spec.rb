require 'spec_helper'

describe VisualizationsController do
  login_admin

  let(:suite) { create(:suite) }

  describe "GET #color_area_chart" do
    it "is successful" do
      get :color_area_chart, suite_id: suite.id
      response.should be_success
    end
  end
  describe "GET #stanine_column_chart" do
    it "is successful" do
      get :stanine_column_chart, suite_id: suite.id
      response.should be_success
    end
  end
  describe "GET #result_line_chart" do
    it "is successful" do
      get :result_line_chart, suite_id: suite.id
      response.should be_success
    end
  end

  describe "POST #filter" do
    it "sets a visualization filter" do
      post :filter, type: "type", filter_categories: "foo,bar", return_to: "/foo/bar"
      response.should redirect_to("/foo/bar")
      session[:visualization_filter][:type][:categories].should == "foo,bar"
    end
    it "redirects to the root url if no return parameter is set" do
      post :filter, type: "type", filter_categories: "foo,bar"
      response.should redirect_to(root_url())
    end
  end

  describe "#results_to_datatable" do
    let!(:students)     { create_list(:student, 2) }
    let!(:participants) { students.collect { |s| create(:participant, suite: suite, student: s) } }
    let!(:evaluations)  { create_list(:suite_evaluation, 2, suite: suite, max_result: 10, _yellow: 4..7) }
    let!(:result_s1_e1) { create(:result, evaluation: evaluations.first,  student: students.first,  value: 4) }
    let!(:result_s1_e2) { create(:result, evaluation: evaluations.second, student: students.first,  value: 5) }
    let!(:result_s2_e1) { create(:result, evaluation: evaluations.first,  student: students.second, value: 6) }

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
      its(:second) { should == result_s1_e1.value.to_f / 10.0 }
      its(:third)  { should == result_s2_e1.value.to_f / 10.0 }
    end

    context "row for evaluation 2" do
      subject { table.third }
      it { should have(3).items }
      its(:first)  { should == evaluations.second.name }
      its(:second) { should == result_s1_e2.value.to_f / 10.0 }
      its(:third)  { should be_nil }
    end

    context "limited by student" do
      let(:table) { controller.send(:results_to_datatable, evaluations, students.first) }

      context "title row" do
        subject { table.first }
        it { should have(2).items }
        its(:first)  { should == Evaluation.model_name.human(count: 2) }
        its(:second) { should == students.first.name }
      end

      context "row for evaluation 1" do
        subject { table.second }
        it { should have(2).items }
        its(:first)  { should == evaluations.first.name }
        its(:second) { should == result_s1_e1.value.to_f / 10.0 }
      end

      context "row for evaluation 2" do
        subject { table.third }
        it { should have(2).items }
        its(:first)  { should == evaluations.second.name }
        its(:second) { should == result_s1_e2.value.to_f / 10.0 }
      end
    end
  end

  describe "#result_colors_to_datatable" do
    let!(:students)     { create_list(:student, 2) }
    let!(:participants) { students.collect { |s| create(:participant, suite: suite, student: s) } }
    let!(:evaluations)  { create_list(:suite_evaluation, 3, suite: suite, max_result: 10, _yellow: 4..7) }
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

  describe "#result_stanines_to_datatable" do
    let!(:students)     { create_list(:student, 3) }
    let!(:participants) { students.collect { |s| create(:participant, suite: suite, student: s) } }
    let!(:evaluations)  { create_list(:suite_evaluation, 2,
      suite: suite,
      max_result: 8,
      _yellow: 4..6,
      _stanines: [ 0..0, 1..1, 2..2, 3..3, 4..4, 5..5, 6..6, 7..7, 8..8 ]
    ) }

    before(:each) do
      [ 3, 3, 5 ].each do |value|
        create(:result, evaluation: evaluations.first, value: value)
      end
      [ 4, 4, 5 ].each do |value|
        create(:result, evaluation: evaluations.second, value: value)
      end
    end

    subject(:table) { controller.send(:result_stanines_to_datatable, evaluations) }

    it { should have(10).items }

    context "title row" do
      subject      { table.first }
      it           { should have(4).items }
      its(:first)  { should == I18n.t(:stanine) }
      its(:second) { should == I18n.t(:normal_distribution) }
      its(:third)  { should == evaluations.first.name }
      its(:fourth) { should == evaluations.second.name }
    end

    [
      [1, 0.04 * 3.0, 0, 0],
      [2, 0.07 * 3.0, 0, 0],
      [3, 0.12 * 3.0, 0, 0],
      [4, 0.17 * 3.0, 2, 0],
      [5, 0.20 * 3.0, 0, 2],
      [6, 0.17 * 3.0, 1, 1],
      [7, 0.12 * 3.0, 0, 0],
      [8, 0.07 * 3.0, 0, 0],
      [9, 0.04 * 3.0, 0, 0],
    ].each do |row, expected_second, expected_third, expected_fourth|
      context "row #{row}" do
        subject      { table[row] }
        it           { should have(4).items }
        its(:first)  { should == row.to_s }
        its(:second) { should == expected_second }
        its(:third)  { should == expected_third }
        its(:fourth) { should == expected_fourth }
      end
    end
  end

  describe "#result_stanines_by_color_to_datatable" do
    let!(:students)     { create_list(:student, 3) }
    let!(:participants) { students.collect { |s| create(:participant, suite: suite, student: s) } }
    let!(:evaluation)   { create(:suite_evaluation,
      suite: suite,
      max_result: 8,
      _yellow: 4..6,
      _stanines: [ 0..0, 1..1, 2..2, 3..3, 4..4, 5..5, 6..6, 7..7, 8..8 ]
    ) }

    before(:each) do
      [ 1, 4, 7 ].each do |value|
        create(:result, evaluation: evaluation, value: value)
      end
      create(:result, evaluation: evaluation, value: nil, absent: true)
    end

    subject(:table) { controller.send(:result_stanines_by_color_to_datatable, evaluation) }

    it { should have(10).items }

    context "title row" do
      subject      { table.first }
      it           { should have(5).items }
      its(:first)  { should == I18n.t(:stanine) }
      its(:second) { should == I18n.t(:normal_distribution) }
      its(:third)  { should == I18n.t(:red) }
      its(:fourth) { should == I18n.t(:yellow) }
      its(:fifth)  { should == I18n.t(:green) }
    end
    [
      [1, 0.04 * 3.0, 0, 0, 0],
      [2, 0.07 * 3.0, 1, 0, 0],
      [3, 0.12 * 3.0, 0, 0, 0],
      [4, 0.17 * 3.0, 0, 0, 0],
      [5, 0.20 * 3.0, 0, 1, 0],
      [6, 0.17 * 3.0, 0, 0, 0],
      [7, 0.12 * 3.0, 0, 0, 0],
      [8, 0.07 * 3.0, 0, 0, 1],
      [9, 0.04 * 3.0, 0, 0, 0],
    ].each do |row, expected_second, expected_third, expected_fourth, expected_fifth|
      context "row #{row}" do
        subject      { table[row] }
        it           { should have(5).items }
        its(:first)  { should == row.to_s }
        its(:second) { should == expected_second }
        its(:third)  { should == expected_third }
        its(:fourth) { should == expected_fourth }
        its(:fifth)  { should == expected_fifth }
      end
    end
  end
end
