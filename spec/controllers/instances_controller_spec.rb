require 'spec_helper'

describe InstancesController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance) { create(:instance) }

  describe "GET #index" do
    let!(:instances) { create_list(:instance, 2) }

    it "lists instances" do
      get :index
      expect(response).to be_successful
      expect(assigns(:instances)).to match_array(instances + [ logged_in_user.active_instance ])
    end

    it "lists instances via xhr" do
      xhr :get, :index
      expect(response).to be_successful
      expect(response).to render_template("_list")
    end

    context "with a regular user" do
      login_user

      it "limits the instances to those the user can access" do
        get :index
        expect(response).to            be_successful
        expect(assigns(:instances)).to match_array([ logged_in_user.active_instance ])
      end
    end
  end

  describe "POST #select" do
    it "sets the current user's active instance" do
      expect(logged_in_user.active_instance).not_to eq instance
      post :select, id: instance.id

      expect(response).to redirect_to(root_url())
      expect(logged_in_user.reload.active_instance).to eq instance
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: instance.id
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new
      expect(response).to be_success
    end
  end
  describe "POST #create" do
    it "redirects to the instance when successful" do
      post :create, instance: valid_parameters_for(:instance)
      expect(response).to redirect_to(assigns(:instance))
    end
    it "renders the new view when validation fails" do
      post :create, instance: invalid_parameters_for(:instance)
      expect(response).to render_template("new")
    end
    context "with admin" do
      let(:admin) { create(:user) }
      it "add roles to admin" do
        params = { name: "instans", user_id: admin.id }
        post :create, instance: params
        expect(admin.has_role?(:member, Instance.where(name: "instans").first)).to be_true
      end
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: instance.id
      expect(response).to be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the instance when successful" do
      new_name = "#{instance.name} updated"
      put :update, id: instance.id, instance: { name: new_name }
      expect(response).to redirect_to(instance)
      expect(instance.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: instance.id, instance: invalid_parameters_for(:instance)
      expect(response).to render_template("edit")
    end
    context "with admin" do
      let(:prev_admin) { create(:user) }
      let(:new_admin) { create(:user) }
      let(:instance) { create(:instance, admin: prev_admin) }
      let!(:suite_1) { create(:suite, instance: instance) }
      let!(:suite_2) { create(:suite, instance: instance) }
      let(:instance_user) { create(:user, instances: [instance]) }
      it "add roles to new admin" do
        params = { name: "instans", user_id: new_admin.id }
        put :update, id: instance.id, instance: params
        expect(new_admin.has_role?(:member, Instance.where(name: "instans").first)).to be_true
      end
      it "removes roles for previous admin" do
        params = { name: "instans", user_id: new_admin.id }
        put :update, id: instance.id, instance: params
        expect(prev_admin.has_role?(:member, Instance.where(name: "instans").first)).to be_false
      end
      it "add suite roles to new admin" do
        params = { name: "instans", user_id: new_admin.id }
        put :update, id: instance.id, instance: params
        expect(new_admin.has_role?(:suite_member, suite_1)).to be_true
        expect(new_admin.has_role?(:suite_member, suite_1)).to be_true
      end
      it "removes suite roles for previous admin" do
        params = { name: "instans", user_id: new_admin.id }
        put :update, id: instance.id, instance: params
        expect(prev_admin.has_role?(:suite_member, suite_1)).to be_false
        expect(prev_admin.has_role?(:suite_member, suite_1)).to be_false
      end
      it "removes roles unless user is member of instance" do
        params = { name: "instans", user_id: instance_user.id }
        put :update, id: instance.id, instance: params
        expect(instance_user.has_role?(:member, Instance.where(name: "instans").first)).to be_true
        expect(instance_user.has_role?(:suite_member, suite_1)).to be_true
        expect(instance_user.has_role?(:suite_member, suite_1)).to be_true

        params = { name: "instans", user_id: new_admin.id }
        put :update, id: instance.id, instance: params
        expect(instance_user.has_role?(:member, Instance.where(name: "instans").first)).to be_true
        expect(instance_user.has_role?(:suite_member, suite_1)).to be_true
        expect(instance_user.has_role?(:suite_member, suite_1)).to be_true
      end
    end
  end
  describe "add user" do
    let!(:instance)  { create(:instance) }
    let!(:user_1)    { create(:user) }
    let!(:user_2)    { create(:user) }
    let!(:suite_1)   { create(:suite, instance: instance) }
    let!(:suite_2)   { create(:suite, instance: instance) }

    it "redirects to the instance when successful" do
      put :add_users, id: instance.id, instance: { }
      expect(response).to redirect_to(instance)
    end
    it "adds all users" do
      put :add_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }

      expect(instance.users.length).to eq 2
      expect(instance.users[0]).to eq user_1
      expect(instance.users[1]).to eq user_2
      expect(response).to redirect_to(instance)
    end
    it "does not add existing user" do
      put :add_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }
      expect(instance.users.length).to eq 2

      put :add_users, id: instance.id, instance: { user_id: [user_1.id].join(",") }
      expect(instance.users.length).to eq 2
      expect(suite_1.users.length).to eq 2
      expect(suite_2.users.length).to eq 2
    end
    it "adds users to suites" do
      put :add_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }

      expect(suite_1.users.length).to eq 2
      expect(suite_1.users[0]).to eq user_1
      expect(suite_1.users[1]).to eq user_2
      expect(suite_2.users.length).to eq 2
      expect(suite_2.users[0]).to eq user_1
      expect(suite_2.users[1]).to eq user_2

      expect(response).to redirect_to(instance)
    end
  end
  describe "remove user" do
    let!(:instance)  { create(:instance) }
    let!(:user_1)    { create(:user) }
    let!(:user_2)    { create(:user) }
    let!(:suite_1)   { create(:suite, instance: instance) }
    let!(:suite_2)   { create(:suite, instance: instance) }

    it "redirects to the instance when successful" do
      put :remove_users, id: instance.id, instance: { }
      expect(response).to redirect_to(instance)

      put :remove_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }
      expect(response).to redirect_to(instance)
    end
    it "removes user" do
      put :add_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }
      expect(instance.users.length).to eq 2

      put :remove_users, id: instance.id, instance: { user_id: "#{user_1.id}" }
      expect(instance.reload.users.length).to eq 1

      expect(response).to redirect_to(instance)
    end
    it "removes all users" do
      put :add_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }
      expect(instance.users.length).to eq 2

      put :remove_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }
      expect(instance.reload.users.length).to eq 0

      expect(response).to redirect_to(instance)
    end
    it "removes users from suites" do
      put :add_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }
      expect(suite_1.users.length).to eq 2
      expect(suite_2.users.length).to eq 2

      put :remove_users, id: instance.id, instance: { user_id: [user_1.id, user_2.id].join(",") }
      expect(suite_1.reload.users.length).to eq 0
      expect(suite_2.reload.users.length).to eq 0

      expect(response).to redirect_to(instance)
    end
  end
end
