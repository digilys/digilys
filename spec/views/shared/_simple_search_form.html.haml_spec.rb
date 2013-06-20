require "spec_helper"

describe "shared/_simple_search_form" do
  before(:each) do
    view.stub(:url_for).and_return("/form/target")
    local(field: "field")
  end
  it "renders without errors" do
    render
  end
  it "renders a clear link if parameters are set" do
    view.stub(:params).and_return(q: { name_cont: "name" })
    render
    rendered.should have_selector("a[href='/form/target']")
  end
end
