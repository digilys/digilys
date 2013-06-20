require "spec_helper"

describe "template/suites/index" do
  let!(:suites) { create_list(:suite, 2) }
  before(:each) do
    assign(:suites, Suite.page(1))
    render
  end
  subject { view }
  it      { should render_template("_navigation") }
  it      { should render_template("suites/_list") }
  it      { should render_template("shared/_simple_search_form") }
end
