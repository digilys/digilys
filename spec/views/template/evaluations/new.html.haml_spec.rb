require "spec_helper"

describe "template/evaluations/new" do
  before(:each) do
    assign(:evaluation, create(:evaluation))
    render
  end
  subject { view }
  it      { should render_template("evaluations/_form") }
end
