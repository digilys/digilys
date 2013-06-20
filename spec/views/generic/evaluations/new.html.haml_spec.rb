require "spec_helper"

describe "generic/evaluations/new" do
  before(:each) do
    assign(:evaluation, create(:evaluation))
    render
  end
  subject { view }
  it      { should render_template("_navigation") }
  it      { should render_template("evaluations/_form") }
end
