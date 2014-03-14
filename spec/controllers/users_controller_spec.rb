require 'spec_helper'

describe UsersController do
  login_user(:admin)

  let(:user) { create(:user) }

  describe "GET #index" do
    let!(:users)           { create_list(:user,           2) }
    let!(:invisible_users) { create_list(:invisible_user, 2) }

    it "lists users in the current instance" do
      get :index
      response.should be_successful
      assigns(:users).should match_array(users + [ logged_in_user ])
    end
    it "is filterable" do
      get :index, q: { name_cont: users.first.name }
      response.should be_successful
      assigns(:users).should == [users.first]
    end
  end

  describe "GET #search" do
    let!(:users)              { create_list(:user,           2, active_instance: logged_in_user.active_instance) }
    let!(:invisible_users)    { create_list(:invisible_user, 2, active_instance: logged_in_user.active_instance) }
    let!(:non_instance_users) { create_list(:user,           2) }

    it "lists users" do
      get :search, q: {}

      response.should be_success
      json = JSON.parse(response.body)

      json["results"].should have(users.length + 1).items
    end
    it "returns the result as json" do
      get :search, q: { name_cont: users.first.name }

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
    it "only touches global roles, not instance roles" do
      user.add_role :superuser
      user.add_role :resource, Instance
      user.add_role :instance, Instance.first

      put :update, id: user.id, user: { role_ids: [Role.find_by_name("admin").id] }

      user.should_not have_role(:superuser)
      user.should     have_role(:admin)
      user.should     have_role(:resource, Instance)
      user.should     have_role(:instance, Instance.first)
      Role.where(name: "superuser").exists?.should be_true
    end

    context "instances" do
      let(:instances) { create_list(:instance, 2) }
      let(:user) { create(:user, active_instance: instances.first) }

      it "changes instances for the user" do
        put :update, id: user.id, user: { instances: [instances.second.id] }
        user.should have_role(:member, instances.second)
        user.should_not have_role(:member, instances.first)
      end
      it "changes the active instance if the active instance is removed" do
        put :update, id: user.id, user: { instances: [instances.second.id] }
        user.reload.active_instance.should == instances.second
      end
      it "removes the active instance if all instances are removed" do
        put :update, id: user.id, user: { instances: [] }
        user.reload.active_instance.should be_nil
      end

      context "without previous" do
        before(:each) do
          Instance.with_role(:member, user).each do |i|
            user.remove_role(:member, i)
          end
          user.active_instance = nil
          user.save
        end
        it "changes instances for the user" do
          put :update, id: user.id, user: { instances: [instances.second.id] }
          user.should have_role(:member, instances.second)
        end
        it "changes the active instance if the active instance is removed" do
          put :update, id: user.id, user: { instances: [instances.second.id] }
          user.reload.active_instance.should == instances.second
        end
        it "removes the active instance if all instances are removed" do
          put :update, id: user.id, user: { instances: [] }
          user.reload.active_instance.should be_nil
        end
      end
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
