require 'spec_helper'

describe UsersController do
  login_admin

  let(:user) { create(:user) }

  describe "GET #index" do
    let!(:users) { create_list(:user, 2) }

    it "lists top level groups" do
      get :index
      response.should be_successful
      assigns(:users).should match_array(User.all)
    end
  end

  describe "GET #search" do
    let!(:users) { create_list(:user, 2) }

    it "returns the result as json" do
      get :search, q: { name_cont: users.first.name }

      response.should be_success
      json = JSON.parse(response.body)

      json["more"].should be_false

      json["results"].should have(1).items
      json["results"].first.should include("id"   => users.first.id)
      json["results"].first.should include("text" => "#{users.first.name}, #{users.first.email}")
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: user.id
      response.should be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the user edit page when successful" do
      new_name = "#{user.name} updated"
      put :update, id: user.id, user: { name: new_name }
      response.should redirect_to(edit_user_path(user))
      user.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: user.id, user: invalid_parameters_for(:user)
      response.should render_template("edit")
    end
    it "changes roles when applicable" do
      user.add_role :superuser
      user.save

      put :update, id: user.id, user: { role_ids: [Role.find_by_name("admin").id] }

      user.has_role?(:superuser).should be_false
      user.has_role?(:admin).should     be_true
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: user.id
      response.should be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the user list page" do
      delete :destroy, id: user.id
      response.should redirect_to(users_url())
      User.exists?(user.id).should be_false
    end
  end
end
