require 'spec_helper'

describe VisualizationsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:suite)       { create(:suite) }
  let(:instance)    { create(:instance) }
  let(:other_suite) { create(:suite, instance: instance) }

  describe "GET #color_area_chart" do
    it "is successful" do
      get :color_area_chart, suite_id: suite.id
      expect(response).to be_success
    end
    it "gives a 404 if the suite's instance does not match" do
      get :color_area_chart, suite_id: other_suite.id
      expect(response.status).to eq 404
    end
  end
  describe "GET #stanine_column_chart" do
    it "is successful" do
      get :stanine_column_chart, suite_id: suite.id
      expect(response).to be_success
    end
    it "gives a 404 if the suite's instance does not match" do
      get :stanine_column_chart, suite_id: other_suite.id
      expect(response.status).to eq 404
    end
  end
  describe "GET #result_line_chart" do
    it "is successful" do
      get :result_line_chart, suite_id: suite.id
      expect(response).to be_success
    end
    it "gives a 404 if the suite's instance does not match" do
      get :result_line_chart, suite_id: other_suite.id
      expect(response.status).to eq 404
    end
  end

  describe "POST #filter" do
    it "sets a visualization filter" do
      post :filter, type: "type", filter_categories: "foo,bar", return_to: "/foo/bar"
      expect(response).to redirect_to("/foo/bar")
      expect(session[:visualization_filter][:type][:categories]).to eq "foo,bar"
    end
    it "redirects to the root url if no return parameter is set" do
      post :filter, type: "type", filter_categories: "foo,bar"
      expect(response).to redirect_to(root_url())
    end
  end

  describe "#results_to_datatable" do
    let!(:students)     { create_list(:student, 3) }
    let!(:participants) { students.collect { |s| create(:participant, suite: suite, student: s) } }
    let!(:evaluations)  { create_list(:suite_evaluation, 2, suite: suite, max_result: 10, _yellow: 4..7) }
    let!(:result_s1_e1) { create(:result, evaluation: evaluations.first,  student: students.first,  value: 4) }
    let!(:result_s1_e2) { create(:result, evaluation: evaluations.second, student: students.first,  value: 5) }
    let!(:result_s2_e1) { create(:result, evaluation: evaluations.first,  student: students.second, value: 6) }
    let!(:result_s3_e1) { create(:result, evaluation: evaluations.first,  student: students.third,  value: nil, absent: true) }
    let!(:result_s3_e2) { create(:result, evaluation: evaluations.second, student: students.third,  value: nil, absent: true) }

    subject(:table) { controller.send(:results_to_datatable, evaluations) }

    it "generates the correct format" do
      expect(table).to have(3).items

      # Title row
      expect(table.first).to have(3).items
      expect(table.first[0]).to eq Evaluation.model_name.human(count: 2)
      expect(table.first[1]).to eq students.first.name
      expect(table.first[2]).to eq students.second.name

      # Row for evaluation 1
      expect(table.second).to have(3).items
      expect(table.second[0]).to eq "#{evaluations.first.name} (#{evaluations.first.date})"
      expect(table.second[1]).to eq result_s1_e1.value.to_f / 10.0
      expect(table.second[2]).to eq result_s2_e1.value.to_f / 10.0

      # Row for evaluation 2
      expect(table.third).to have(3).items
      expect(table.third[0]).to eq "#{evaluations.second.name} (#{evaluations.second.date})"
      expect(table.third[1]).to eq result_s1_e2.value.to_f / 10.0
      expect(table.third[2]).to be_nil
    end


    context "limited by student" do
      let(:table) { controller.send(:results_to_datatable, evaluations, students.first) }

      it "generates the correct format" do
        expect(table).to have(3).items

        # Title row
        expect(table.first).to have(2).items
        expect(table.first[0]).to eq Evaluation.model_name.human(count: 2)
        expect(table.first[1]).to eq students.first.name

        # Row for evaluation 1
        expect(table.second).to have(2).items
        expect(table.second[0]).to eq "#{evaluations.first.name} (#{evaluations.first.date})"
        expect(table.second[1]).to eq result_s1_e1.value.to_f / 10.0

        # Row for evaluation 2
        expect(table.third).to have(2).items
        expect(table.third[0]).to eq "#{evaluations.second.name} (#{evaluations.second.date})"
        expect(table.third[1]).to eq result_s1_e2.value.to_f / 10.0
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
      expect(table).to have(4).items

      # Title row
      expect(table.first).to have(4).items
      expect(table.first[0]).to eq Evaluation.model_name.human(count: 2)
      expect(table.first[1]).to eq I18n.t(:red)
      expect(table.first[2]).to eq I18n.t(:yellow)
      expect(table.first[3]).to eq I18n.t(:green)

      # Row for evaluation 1
      expect(table.second).to have(4).items
      expect(table.second[0]).to eq "#{evaluations.first.name} (#{evaluations.first.date})"
      expect(table.second[1]).to eq evaluations.first.result_distribution[:red]
      expect(table.second[2]).to eq evaluations.first.result_distribution[:yellow]
      expect(table.second[3]).to eq evaluations.first.result_distribution[:green]

      # Row for evaluation 2
      expect(table.third).to have(4).items
      expect(table.third[0]).to eq "#{evaluations.second.name} (#{evaluations.second.date})"
      expect(table.third[1]).to eq evaluations.second.result_distribution[:red]
      expect(table.third[2]).to eq evaluations.second.result_distribution[:yellow]
      expect(table.third[3]).to eq evaluations.second.result_distribution[:green]

      # Row for evaluation 3
      expect(table.fourth).to have(4).items
      expect(table.fourth[0]).to eq "#{evaluations.third.name} (#{evaluations.third.date})"
      expect(table.fourth[1]).to eq 0
      expect(table.fourth[2]).to eq 0
      expect(table.fourth[3]).to eq 0
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
      expect(table).to have(10).items

      # Title row
      expect(table.first).to have(4).items
      expect(table.first[0]).to eq I18n.t(:stanine)
      expect(table.first[1]).to eq I18n.t(:normal_distribution)
      expect(table.first[2]).to eq "#{evaluations.first.name} (#{evaluations.first.date})"
      expect(table.first[3]).to eq "#{evaluations.second.name} (#{evaluations.second.date})"

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
        expect(table[row]).to have(4).items
        expect(table[row][0]).to eq row.to_s
        expect(table[row][1]).to eq expected_second
        expect(table[row][2]).to eq expected_third
        expect(table[row][3]).to eq expected_fourth
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
      expect(table).to have(10).items

      # Title row
      expect(table.first).to have(5).items
      expect(table.first[0]).to eq I18n.t(:stanine)
      expect(table.first[1]).to eq I18n.t(:normal_distribution)
      expect(table.first[2]).to eq I18n.t(:red)
      expect(table.first[3]).to eq I18n.t(:yellow)
      expect(table.first[4]).to eq I18n.t(:green)

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
        expect(table[row]).to have(5).items
        expect(table[row][0]).to eq row.to_s
        expect(table[row][1]).to eq expected_second
        expect(table[row][2]).to eq expected_third
        expect(table[row][3]).to eq expected_fourth
        expect(table[row][4]).to eq expected_fifth
      end
    end
  end
end
