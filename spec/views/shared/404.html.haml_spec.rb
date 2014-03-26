require "spec_helper"

describe "shared/404" do
  it "renders without errors" do
    render
  end
  it "includes links back when a referrer is set" do
    view.request.stub(:referer).and_return("/referer/path")
    render
    expect(rendered).to have_selector("a[href='/referer/path']")
  end
  it "includes a link to the controller's index page if available" do
    controller.stub(:index).and_return(nil)
    view.stub(:url_for).and_return("#")
    view.should_receive(:url_for).with(action: "index").and_return("/shared/index")

    render
    expect(rendered).to have_selector("a[href='/shared/index']")
  end
end
