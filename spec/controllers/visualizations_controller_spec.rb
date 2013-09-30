require 'spec_helper'

describe VisualizationsController do
  login_user(:admin)

  let(:suite)       { create(:suite) }
  let(:instance)    { create(:instance) }
  let(:other_suite) { create(:suite, instance: instance) }

  describe "GET #color_area_chart" do
    it "is successful" do
      get :color_area_chart, suite_id: suite.id
      response.should be_success
    end
    it "gives a 404 if the suite's instance does not match" do
      get :color_area_chart, suite_id: other_suite.id
      response.status.should == 404
    end
  end
  describe "GET #stanine_column_chart" do
    it "is successful" do
      get :stanine_column_chart, suite_id: suite.id
      response.should be_success
    end
    it "gives a 404 if the suite's instance does not match" do
      get :stanine_column_chart, suite_id: other_suite.id
      response.status.should == 404
    end
  end
  describe "GET #result_line_chart" do
    it "is successful" do
      get :result_line_chart, suite_id: suite.id
      response.should be_success
    end
    it "gives a 404 if the suite's instance does not match" do
      get :result_line_chart, suite_id: other_suite.id
      response.status.should == 404
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

    it "generates the correct format" do
      table.should have(3).items

      # Title row
      table.first.should have(3).items
      table.first[0].should == Evaluation.model_name.human(count: 2)
      table.first[1].should == students.first.name
      table.first[2].should == students.second.name

      # Row for evaluation 1
      table.second.should have(3).items
      table.second[0].should == evaluations.first.name
      table.second[1].should == result_s1_e1.value.to_f / 10.0
      table.second[2].should == result_s2_e1.value.to_f / 10.0

      # Row for evaluation 2
      table.third.should have(3).items
      table.third[0].should == evaluations.second.name
      table.third[1].should == result_s1_e2.value.to_f / 10.0
      table.third[2].should be_nil
    end


    context "limited by student" do
      let(:table) { controller.send(:results_to_datatable, evaluations, students.first) }

      it "generates the correct format" do
        table.should have(3).items

        # Title row
        table.first.should have(2).items
        table.first[0].should == Evaluation.model_name.human(count: 2)
        table.first[1].should == students.first.name

        # Row for evaluation 1
        table.second.should have(2).items
        table.second[0].should == evaluations.first.name
        table.second[1].should == result_s1_e1.value.to_f / 10.0

        # Row for evaluation 2
        table.third.should have(2).items
        table.third[0].should == evaluations.second.name
        table.third[1].should == result_s1_e2.value.to_f / 10.0
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

    it "generates the correct format" do
      table.should have(4).items

      # Title row
      table.first.should have(4).items
      table.first[0].should == Evaluation.model_name.human(count: 2)
      table.first[1].should == I18n.t(:red)
      table.first[2].should == I18n.t(:yellow)
      table.first[3].should == I18n.t(:green)

      # Row for evaluation 1
      table.second.should have(4).items
      table.second[0].should == evaluations.first.name
      table.second[1].should == evaluations.first.result_distribution[:red]
      table.second[2].should == evaluations.first.result_distribution[:yellow]
      table.second[3].should == evaluations.first.result_distribution[:green]

      # Row for evaluation 2
      table.third.should have(4).items
      table.third[0].should == evaluations.second.name
      table.third[1].should == evaluations.second.result_distribution[:red]
      table.third[2].should == evaluations.second.result_distribution[:yellow]
      table.third[3].should == evaluations.second.result_distribution[:green]

      # Row for evaluation 3
      table.fourth.should have(4).items
      table.fourth[0].should == evaluations.third.name
      table.fourth[1].should == 0
      table.fourth[2].should == 0
      table.fourth[3].should == 0
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

    it "generates the correct format" do
      table.should have(10).items

      # Title row
      table.first.should have(4).items
      table.first[0].should == I18n.t(:stanine)
      table.first[1].should == I18n.t(:normal_distribution)
      table.first[2].should == evaluations.first.name
      table.first[3].should == evaluations.second.name

      # Stanine rows
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
        table[row].should have(4).items
        table[row][0].should == row.to_s
        table[row][1].should == expected_second
        table[row][2].should == expected_third
        table[row][3].should == expected_fourth
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

    it "generates the correct format" do
      table.should have(10).items

      # Title row
      table.first.should have(5).items
      table.first[0].should == I18n.t(:stanine)
      table.first[1].should == I18n.t(:normal_distribution)
      table.first[2].should == I18n.t(:red)
      table.first[3].should == I18n.t(:yellow)
      table.first[4].should == I18n.t(:green)

      # Stanine rows
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
        table[row].should have(5).items
        table[row][0].should == row.to_s
        table[row][1].should == expected_second
        table[row][2].should == expected_third
        table[row][3].should == expected_fourth
        table[row][4].should == expected_fifth
      end
    end
  end
end
