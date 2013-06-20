require "spec_helper"

describe "template/evaluations/index" do
  let!(:evaluations) { create_list(:evaluation, 2) }
  before(:each) do
    assign(:evaluations, Evaluation.page(1))
    render
  end
  subject { view }
  it      { should render_template("_navigation") }
  it      { should render_template("evaluations/_list") }
  it      { should render_template("shared/_simple_search_form") }
end
