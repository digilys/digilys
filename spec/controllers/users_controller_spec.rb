require 'spec_helper'

describe UsersController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:user)           { create(:user) }
  let(:instance_admin) { create(:user) }

  context "non admin" do
    login_user(:user)
    describe "GET #new" do
      it "should return 401" do
        get :new
        expect(response.status).to be 401
      end
    end
    describe "GET #edit" do
      it "should return 401" do
        get :edit, id: user
        expect(response.status).to be 401
      end
    end
    describe "POST #create" do
      it "should return 401" do
        post :create, user: valid_parameters_for(:user)
        expect(response.status).to be 401
      end
    end
  end

  describe "GET #index" do
    login_user(:admin)
    let!(:users)           { create_list(:user,           2) }
    let!(:invisible_users) { create_list(:invisible_user, 2) }

    before(:each) do
      users.each do |u|
        u.add_role(:member, logged_in_user.active_instance)
        u.save
        logged_in_user.add_role(:member, logged_in_user.active_instance)
        logged_in_user.save
      end
    end

    it "lists users in the current instance" do
      get :index
      expect(response).to be_successful
      expect(assigns(:users)).to match_array(users + [ logged_in_user ])
    end
    it "is filterable" do
      get :index, q: { name_cont: users.first.name }
      expect(response).to be_successful
      expect(assigns(:users)).to eq [users.first]
    end

    context "as instance admin" do
      login_user(:user)
      let!(:other_instance)  { create(:instance) }
      let!(:users)           { create_list(:user, 3, active_instance: logged_in_user.active_instance) }
      before(:each) do
        users.first.add_role(:admin)
        users.second.add_role(:superuser)
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "does not list admins" do
        get :index
        expect(response).to be_successful
        expect(assigns(:users)).to match_array([ users.second, users.third, logged_in_user ])
      end
      it "only lists instance members" do
        users.third.remove_role(:member, logged_in_user.active_instance)
        get :index
        expect(response).to be_successful
        expect(assigns(:users)).to match_array([ users.second, logged_in_user ])
      end
    end
  end

  describe "GET #search" do
    let!(:users)              { create_list(:user,           2, active_instance: logged_in_user.active_instance) }
    let!(:invisible_users)    { create_list(:invisible_user, 2, active_instance: logged_in_user.active_instance) }
    let!(:non_instance_users) { create_list(:user,           2) }

    it "lists users" do
      get :search, q: {}

      expect(response).to be_success
      json = JSON.parse(response.body)

      expect(json["results"]).to have(users.length + 1).items
    end
    it "returns the result as json" do
      get :search, q: { name_cont: users.first.name }

      json = JSON.parse(response.body)

      expect(json["more"]).to be_false

      expect(json["results"]).to have(1).items
      expect(json["results"].first).to include("id"   => users.first.id)
      expect(json["results"].first).to include("text" => "#{users.first.name}, #{users.first.email}")
    end

    context "as instance admin" do
      login_user(:user)
      before(:each) do
        users.second.remove_role(:member, logged_in_user.active_instance)
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "only lists instance members" do
        get :search, q: {}

        expect(response).to be_success
        json = JSON.parse(response.body)

        expect(json["results"]).to have(users.length).items
      end
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: user.id
      expect(response).to be_success
    end
    it "generates a 404 if the user does not exist" do
      get :edit, id: -1
      expect(response.status).to be 404
    end
    context "as instance admin" do
      login_user(:user)
      let!(:member)       { create(:user, active_instance: logged_in_user.active_instance) }
      let!(:admin)        { create(:admin, active_instance: logged_in_user.active_instance) }
      let!(:non_member)   { create(:user) }
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "is successful for instance member" do
        get :edit, id: member.id
        expect(response).to be_success
      end
      it "generates a 401 for non instance member" do
        get :edit, id: non_member.id
        expect(response.status).to be 401
      end
      it "generates a 401 for admins" do
        get :edit, id: admin.id
        expect(response.status).to be 401
      end
    end
  end

  describe "PUT #update" do
    it "redirects to the user edit page when successful" do
      new_name = "#{user.name} updated"
      put :update, id: user.id, user: { name: new_name }
      expect(response).to redirect_to(edit_user_path(user))
      expect(user.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: user.id, user: invalid_parameters_for(:user)
      expect(response).to render_template("edit")
    end
    it "changes roles when applicable" do
      user.add_role :superuser
      user.save

      put :update, id: user.id, user: { role_ids: [Role.find_by_name("admin").id] }

      expect(user.has_role?(:superuser)).to be_false
      expect(user.has_role?(:admin)).to     be_true
    end
    it "only touches global roles, not instance roles" do
      user.add_role :superuser
      user.add_role :resource, Instance
      user.add_role :instance, Instance.first

      put :update, id: user.id, user: { role_ids: [Role.find_by_name("admin").id] }

      expect(user).not_to have_role(:superuser)
      expect(user).to     have_role(:admin)
      expect(user).to     have_role(:resource, Instance)
      expect(user).to     have_role(:instance, Instance.first)
      expect(Role.where(name: "superuser").exists?).to be_true
    end

    context "instances" do
      let(:instances) { create_list(:instance, 2) }
      let(:user) { create(:user, active_instance: instances.first) }

      it "changes instances for the user" do
        put :update, id: user.id, user: { instance_ids: [instances.second.id] }
        expect(user).to have_role(:member, instances.second)
        expect(user).not_to have_role(:member, instances.first)
      end
      it "changes the active instance if the active instance is removed" do
        put :update, id: user.id, user: { instance_ids: [instances.second.id] }
        expect(user.reload.active_instance).to eq instances.second
      end
      it "removes the active instance if all instances are removed" do
        put :update, id: user.id, user: { instance_ids: [] }
        expect(user.reload.active_instance).to be_nil
      end

      context "with previous" do
        let!(:admin) { create(:user) }
        let!(:suite_1) { create(:suite, instance: instances.first) }
        let!(:suite_2) { create(:suite, instance: instances.second) }
        before(:each) do
          admin.admin_instance = instances.first
          admin.save
          user.instances = [instances.first]
          user.save
        end
        it "adds roles to new instances" do
          put :update, id: user.id, user: { instance_ids: [instances.second] }
          expect(user.has_role?(:member, instances.second)).to be_true
        end
        it "adds roles to new instance suites" do
          put :update, id: user.id, user: { instance_ids: [instances.second] }
          expect(user.has_role?(:suite_member, suite_2)).to be_true
        end
        it "removes roles from old instances" do
          put :update, id: user.id, user: { instance_ids: [instances.second] }
          expect(user.has_role?(:member, instances.first)).to be_false
        end
        it "removes roles from old suites" do
          put :update, id: user.id, user: { instance_ids: [instances.second] }
          expect(user.has_role?(:suite_member, suite_1)).to be_false
        end
        it "do not remove roles if user is admin of instance" do
          put :update, id: admin.id, user: { instance_ids: [instances.first] }
          expect(admin.has_role?(:member, instances.first)).to be_true
          expect(admin.has_role?(:suite_member, suite_1)).to be_true
          put :update, id: admin.id, user: { instance_ids: [instances.second] }
          expect(admin.has_role?(:member, instances.first)).to be_true
          expect(admin.has_role?(:suite_member, suite_1)).to be_true
        end
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
          put :update, id: user.id, user: { instance_ids: [instances.second.id] }
          expect(user).to have_role(:member, instances.second)
        end
        it "changes the active instance if the active instance is removed" do
          put :update, id: user.id, user: { instance_ids: [instances.second.id] }
          expect(user.reload.active_instance).to eq instances.second
        end
        it "removes the active instance if all instances are removed" do
          put :update, id: user.id, user: { instance_ids: [] }
          expect(user.reload.active_instance).to be_nil
        end
      end
    end
    context "as instance admin" do
      login_user(:user)
      let!(:instance)     { create(:instance) }
      let!(:member)       { create(:user, active_instance: logged_in_user.active_instance) }
      let!(:admin)        { create(:admin, active_instance: logged_in_user.active_instance) }
      let!(:non_member)   { create(:user) }
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "can update instance members" do
        new_name = "#{member.name} updated"
        put :update, id: member.id, user: { name: new_name }
        expect(response).to redirect_to(edit_user_path(member))
        expect(member.reload.name).to eq new_name
      end
      it "can not update non members" do
        new_name = "#{non_member.name} updated"
        put :update, id: non_member.id, user: { name: new_name }
        expect(response.status).to be 401  # redirect_to(edit_user_path(member)) # be 401
      end
      it "can not update admins" do
        new_name = "#{admin.name} updated"
        put :update, id: admin.id, user: { name: new_name }
        expect(response.status).to be 401
      end
      it "can not add other instances" do
        put :update, id: member.id, user: { instance_ids: [instance.id] }
        expect(member.reload.active_instance).to be nil
      end
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: user.id
      expect(response).to be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the user list page" do
      delete :destroy, id: user.id
      expect(response).to redirect_to(users_url())
      expect(User.exists?(user.id)).to be_false
    end
    context "as instance admin" do
      login_user(:user)
      let!(:instance)     { create(:instance) }
      let!(:member)       { create(:user, active_instance: logged_in_user.active_instance) }
      let!(:admin)        { create(:admin, active_instance: logged_in_user.active_instance) }
      let!(:non_member)   { create(:user) }
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "can delete instance member" do
        delete :destroy, id: member.id
        expect(response).to redirect_to(users_url())
        expect(User.exists?(member.id)).to be_false
      end
      it "can not delete non members" do
        delete :destroy, id: non_member.id
        expect(response.status).to be 401  # redirect_to(edit_user_path(member)) # be 401
      end
      it "can not delete admins" do
        delete :destroy, id: admin.id
        expect(response.status).to be 401
      end
    end
  end
  describe "GET #new" do
    it "builds a user" do
      get :new
      expect(response).to be_success
    end
  end
  describe "POST #create" do
    let!(:instance_1) { create(:instance) }
    let!(:instance_2) { create(:instance) }
    let!(:suite_1) { create(:suite, instance: instance_1) }
    let!(:suite_2) { create(:suite, instance: instance_2) }

    it "redirects to users page on success" do
      post :create, user: valid_parameters_for(:user)
      expect(response).to redirect_to(users_path)
    end
    it "renders the new action on invalid parameters" do
      post :create, user: invalid_parameters_for(:user)
      expect(response).to render_template("new")
    end
    it "adds instances" do
      params = valid_parameters_for(:user)
      params["instance_ids"] = [instance_1.id, instance_2.id]
      post :create, user: params
      expect(response).to redirect_to(users_path)
      expect(User.last.instances.size).to eq 2
    end
    it "add roles to instances" do
      params = valid_parameters_for(:user)
      params["instance_ids"] = [instance_1.id, instance_2.id]
      post :create, user: params
      expect(User.last.has_role?(:member, instance_1)).to be_true
      expect(User.last.has_role?(:member, instance_2)).to be_true
    end
    it "add roles to instance suites" do
      params = valid_parameters_for(:user)
      params["instance_ids"] = [instance_1.id, instance_2.id]
      post :create, user: params
      expect(User.last.has_role?(:suite_member, suite_1)).to be_true
      expect(User.last.has_role?(:suite_member, suite_2)).to be_true
    end
    it "add roles" do
      params = valid_parameters_for(:user)
      params[:role_ids] = [Role.find_by_name("admin").id]
      post :create, user: params
      expect(User.last.has_role?(:admin)).to be_true
    end
    context "as instance admin" do
      login_user(:user)
      let!(:instance)         { create(:instance) }
      let!(:instance_suite)   { create(:suite, instance: logged_in_user.active_instance) }
      before(:each) do
        logged_in_user.remove_role(:admin)
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "can create for own instance" do
        params = valid_parameters_for(:user)
        params["instance_ids"] = [logged_in_user.active_instance.id]
        post :create, user: params
        expect(response).to redirect_to(users_path)
        expect(User.last.has_role?(:suite_member, instance_suite)).to be_true
        expect(User.last.has_role?(:member, logged_in_user.active_instance)).to be_true
      end
      it "can only add own instance to instances" do
        params = valid_parameters_for(:user)
        params["instance_ids"] = [logged_in_user.active_instance.id, instance_1.id, instance_2.id]
        post :create, user: params
        expect(response).to redirect_to(users_path)
        expect(User.last.has_role?(:member, logged_in_user.active_instance)).to be_true
        expect(User.last.has_role?(:member, instance_1)).to be_false
        expect(User.last.has_role?(:member, instance_2)).to be_false
        expect(User.last.has_role?(:suite_member, instance_suite)).to be_true
        expect(User.last.has_role?(:suite_member, suite_1)).to be_false
        expect(User.last.has_role?(:suite_member, suite_2)).to be_false
      end
    end
  end
end
