require "spec_helper"

describe "activities/confirm_destroy" do
  let(:activity) { create(:activity) }
  before(:each) do
    assign(:activity, activity)
    render
  end

  subject { rendered }
  it      { should have_selector("h1", text: activity.name) }

  context "rendered fragments" do
    subject { view }
    it      { should render_template("_navigation") }
    it      { should render_template("shared/_confirm_destroy_form") }
  end
end
