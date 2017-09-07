require "spec_helper"

describe "users/edit" do
  let(:user)         { create(:user) }
  let!(:instances)   { create_list(:instance, 3) }
  let(:current_user) { user }
  let(:is_admin)     { false }

  before(:each) do
    view.stub(:current_user).and_return(current_user)
    view.stub(:can?).and_return(is_admin)
    assign(:user, user)
    current_user.add_role(:admin)
    render
  end

  subject { rendered }
  it      { should_not have_selector("h1", text: user.name) }
  it      { should     have_selector("input[name='user[current_password]']") }
  it      { should_not have_selector("input[name='select[role_ids][]']") }

  context "for admin" do
    let(:current_user) { create(:user) }
    let(:is_admin)     { true }
    it                 { should     have_selector("h1", text: user.name) }
    it                 { should_not have_selector("input[name='user[current_password]']") }
    it                 { should     have_selector("select[name='user[role_ids][]']") }
    it                 { should have_selector("input[name='user[instance_ids][]']", count: (Instance.all.reject {|i| i.virtual?}).count + 1) }
  end
  context "for instance admin" do
    let(:current_user) { create(:user) }
    let(:is_admin)     { false }
    before(:each) do
      current_user.add_role(:instance_admin, current_user.active_instance)
    end
    it                 { should     have_selector("h1", text: user.name) }
    it                 { should_not have_selector("input[name='user[current_password]']") }
    it                 { should_not have_selector("select[name='user[role_ids][]']") }
    it                 { should_not have_selector("input[name='user[instance_ids][]']") }
  end
end
