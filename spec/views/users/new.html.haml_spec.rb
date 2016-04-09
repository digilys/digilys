require "spec_helper"

describe "users/new" do
  let(:user)         { create(:user, name: "current_user") }
  let!(:instances)   { create_list(:instance, 2) }
  let(:current_user) { user }
  let(:is_admin)     { false }

  before(:each) do
    view.stub(:current_user).and_return(current_user)
    assign(:user, User.new)
    render
  end

  subject { rendered }
  context "for admin" do
    let(:current_user) { create(:admin) }
    it                 { should     have_selector("input[id='user_name']") }
    it                 { should     have_selector("input[id='user_email']") }
    it                 { should     have_selector("input[id='user_password']") }
    it                 { should_not have_selector("input[name='user[current_password]']") }
    it                 { should_not have_selector("select[name='user[role_ids][]']") }
    it                 { should have_selector("input[name='user[instance_ids][]']", count: Instance.count + 1) }
  end
  context "for instance admin" do
    login_user(:user)
    before(:each) do
      current_user.admin_instance = current_user.active_instance
      current_user.save!
    end
    it                 { should     have_selector("input[id='user_name']") }
    it                 { should     have_selector("input[id='user_email']") }
    it                 { should     have_selector("input[id='user_password']") }
    it                 { should_not have_selector("input[name='user[current_password]']") }
    it                 { should_not have_selector("select[name='user[role_ids][]']") }
    it                 { should have_selector("input[name='user[instance_ids][]']", count: 2) }
  end
end
