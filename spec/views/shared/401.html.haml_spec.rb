require "spec_helper"

describe "shared/401" do
  it "renders without errors" do
    render
  end
  it "includes links back when a referrer is set" do
    view.request.stub(:referer).and_return("/referer/path")
    render
    expect(rendered).to have_selector("a[href='/referer/path']")
  end
end
