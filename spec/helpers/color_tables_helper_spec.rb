require 'spec_helper'

describe ColorTablesHelper do
  describe "#group_hierarchy_options" do
    let!(:l1_group1)   { create(:group) }
    let!(:l1_group2)   { create(:group) }
    let!(:l2_group1)   { create(:group, parent: l1_group1) }
    let!(:l2_group2)   { create(:group, parent: l1_group1) }
    let!(:l3_group1)   { create(:group, parent: l2_group1) }
    let!(:l3_group2)   { create(:group, parent: l2_group1) }
    let!(:l3_group3)   { create(:group, parent: l2_group2) }

    let!(:student1)    { create(:student) }
    let!(:student2)    { create(:student) }

    let!(:evaluation1) { create(:generic_evaluation) }
    let!(:evaluation2) { create(:generic_evaluation) }

    let!(:result1)     { create(:result, student: student1, evaluation: evaluation1) }
    let!(:result2)     { create(:result, student: student2, evaluation: evaluation2) }

    let(:color_table) { create(:color_table) }

    before(:each) do
      student1.add_to_groups(l3_group1)
      student2.add_to_groups(l3_group3)

      color_table.evaluations = [ evaluation1, evaluation2 ]
    end

    subject(:options) { group_hierarchy_options(color_table) }

    it "collects the groups in the hierarchy for display in a select" do
      expect(options).to eq [
        [ l1_group1.name, l1_group1.id ],
        [ "#{l2_group1.name}, #{l1_group1.name}", l2_group1.id ],
        [ "#{l3_group1.name}, #{l2_group1.name}", l3_group1.id ],
        [ "#{l2_group2.name}, #{l1_group1.name}", l2_group2.id ],
        [ "#{l3_group3.name}, #{l2_group2.name}", l3_group3.id ]
      ]
    end
  end

  describe "#color_table_columns" do
    let(:evaluation)  { build(:generic_evaluation, id: 123) }
    let(:name_column) { {
      id:       "student-name",
      name:     Student.human_attribute_name(:name),
      field:    "name",
      type:     "student-name",
      cssClass: "student-name" }.to_json }

    it "renders a name column, student data columns and evaluation columns" do
      should_receive(:student_data_columns).with(%w(Foo)).and_return(["student_data_columns"])
      should_receive(:evaluation_columns).with([evaluation]).and_return(["evaluation_columns"])

      result = color_table_columns(%w(Foo), [evaluation])

      expect(result).to eq "#{name_column},student_data_columns,evaluation_columns"
    end
    it "ignores missing columns" do
      should_receive(:student_data_columns).at_least(:once).and_return { |a| a.blank? ? nil : %w(student_data_columns) }
      should_receive(:evaluation_columns).at_least(:once).and_return { |a| a.blank? ? nil : %w(evaluation_columns) }

      expect(color_table_columns([], [evaluation])).to eq "#{name_column},evaluation_columns"
      expect(color_table_columns(%w(Foo), [])).to eq "#{name_column},student_data_columns"
      expect(color_table_columns([], [])).to eq "#{name_column}"
    end
  end

  describe "#student_data_columns" do
    it "returns nil if there is no student data" do
      expect(student_data_columns([])).to be_nil
    end
    it "generates slick grid column definitions" do
      results = student_data_columns(%w(foo bar\ baz))
      expect(results).to have(2).items

      expect(JSON.parse(results.first)).to eq({
        id:    "student-data-foo",
        name:  "foo",
        field: "student_data_foo",
        type:  "student-data"
      }.stringify_keys)

      expect(JSON.parse(results.second)).to eq({
        id:    "student-data-bar-baz",
        name:  "bar baz",
        field: "student_data_bar_baz",
        type:  "student-data"
      }.stringify_keys)
    end
  end

  describe "#evaluation_columns" do
    let(:evaluation) { build(:evaluation, id: 123) }

    it "returns nil if there are no evaluations" do
      expect(evaluation_columns([])).to be_nil
    end

    it "generates slick grid column definitions" do
      should_receive(:evaluation_info).and_return("evaluation_info")

      results = evaluation_columns([evaluation])
      expect(results).to have(1).items

      expect(JSON.parse(results.first)).to eq({
        id:        "evaluation-123",
        name:      evaluation.name,
        field:     "evaluation_123",
        type:      "evaluation",
        date:      evaluation.date.to_s,
        title:     "evaluation_info",
        maxResult: evaluation.max_result.to_f,
        stanines:  evaluation.stanines?
      }.stringify_keys)
    end
  end

  describe "#result_rows" do
    let(:evaluation) { create(:generic_evaluation) }
    let(:group)      { create(:group) }
    let(:student)    { create(:student, data: { "foo" => 123, "bar baz" => "zomg" }, groups: [group]) }
    let(:result)     { create(:result, evaluation: evaluation, student: student) }

    it "returns a blank string when there are no students" do
      expect(result_rows([], %w(foo bar\ baz), [evaluation])).to be_blank
    end
    it "generates a slick grid data definition for a student" do
      result
      data = result_rows([student], %w(foo bar\ baz), [evaluation])

      expect(data).to have(2).items

      expect(JSON.parse(data.first)).to eq({
        id:                   student.id,
        name:                 student.name,
        groups:               [group.id],
        student_data_foo:     "123",
        student_data_bar_baz: "zomg",
        "evaluation_#{evaluation.id}" => {
          display:  result.display_value,
          value:    result.value,
          stanine:  result.stanine,
          cssClass: result.color.to_s
        }.stringify_keys
      }.stringify_keys)

      # Averages
      expect(JSON.parse(data.second)["id"]).to eq 0
    end

    context "average calculation" do
      let!(:results) { [
        create(:result, evaluation: evaluation, value: 5),
        create(:result, evaluation: evaluation, value: 10),
        create(:result, evaluation: evaluation, value: nil, absent: true)
      ] }

      let(:students) { [ student, *results.collect(&:student) ] }

      it "handles absent results and missing results" do
        data = result_rows(students, [], [evaluation])

        expect(JSON.parse(data.last)).to eq({
          id:   0,
          name: t(:"color_tables.show.averages"),
          "evaluation_#{evaluation.id}" => 7.5
        }.stringify_keys)
      end
    end
    context "for evaluation series" do
      let(:series)      { create(:series) }
      let(:evaluation)  { create(:suite_evaluation, series: series, is_series_current: false) }
      let(:evaluation2) { create(:suite_evaluation, series: series, is_series_current: true)  }
      
      it "displays the latest result in the series for the student" do
        result
        data = JSON.parse(result_rows([student], %w(foo bar\ baz), [evaluation2]).first)
        expect(data["evaluation_#{evaluation2.id}"]).to include("value" => result.value)
      end
    end
  end
end
