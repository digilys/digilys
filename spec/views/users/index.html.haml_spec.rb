require "spec_helper"

describe "users/index" do
  let(:users) { create_list(:user, 2) }
  before(:each) do
    view.stub(:current_user).and_return(users.first)
    assign(:users, users)
    render
  end

  subject { rendered }
  it      { should have_selector(".users-table tbody tr", count: 2) }
  it      { should have_selector(".users-table tbody a.btn-danger", count: 1) }

  context "rendered fragments" do
    subject { view }
    it      { should render_template("shared/_simple_search_form") }
  end
end
