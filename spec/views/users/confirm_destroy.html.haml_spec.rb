require "spec_helper"

describe "users/confirm_destroy" do
  let(:user) { create(:user) }
  before(:each) do
    assign(:user, user)
    render
  end

  subject { rendered }
  it      { should have_selector("h1", text: user.name) }

  context "rendered fragments" do
    subject { view }
    it      { should render_template("shared/_confirm_destroy_form") }
  end
end
