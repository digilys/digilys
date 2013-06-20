require "spec_helper"

describe "activities/edit" do
  let(:activity) { create(:activity, status: :open) }
  before(:each) do
    assign(:activity, activity)
    render
  end

  subject { rendered }
  it      { should have_selector("h1",       text: activity.name) }
  it      { should have_selector("textarea", count: 1) }

  context "with closed activity" do
    let(:activity) { create(:activity, status: :closed) }
    it             { should have_selector("textarea", count: 2) }
  end

  context "rendered fragments" do
    subject { view }
    it      { should render_template("_navigation") }
  end
end
