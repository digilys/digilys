require "spec_helper"

describe "users/index" do
  login_user(:admin)
  let(:users) { create_list(:user, 2) }
  before(:each) do
    users << logged_in_user
    view.stub(:current_user).and_return(users.first)
    assign(:users, Kaminari.paginate_array(users).page(1).per(10))
    render
  end

  subject { rendered }
  it      { should have_selector(".users-table tbody tr", count: 3) }
  it      { should have_selector(".users-table tbody a.btn-mini", count: 5) }
  it      { should have_selector(".users-table tbody a.btn-danger", count: 2) }

  context "rendered fragments" do
    subject { view }
    it      { should render_template("shared/_simple_search_form") }
  end
end

describe "users/index" do
  login_user(:user)
  let(:users) { create_list(:user, 2) }
  before(:each) do
    logged_in_user.add_role(:instance_admin, logged_in_user.active_instance)
    logged_in_user.save

    users << logged_in_user
    assign(:users, Kaminari.paginate_array(users).page(1).per(10))
    render
  end
  context "instance admin" do
    subject { rendered }
    it      { should have_selector(".users-table tbody tr", count: 3) }
    it      { should have_selector(".users-table tbody a.btn-mini", count: 5) }
    it      { should have_selector(".users-table tbody a.btn-danger", count: 2) }
  end
end
