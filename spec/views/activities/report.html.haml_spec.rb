require "spec_helper"

describe "activities/report" do
  let(:activity) { create(:activity, status: :open) }
  before(:each) do
    assign(:activity, activity)
    render
  end

  subject { rendered }
  it      { should have_selector("h1", text: activity.name) }

  context "rendered fragments" do
    subject { view }
    it      { should render_template("_navigation") }
  end
end
