require 'spec_helper'

describe UsersController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:user) { create(:user) }

  describe "GET #index" do
    let!(:users)           { create_list(:user,           2) }
    let!(:invisible_users) { create_list(:invisible_user, 2) }

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
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: user.id
      expect(response).to be_success
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
        put :update, id: user.id, user: { instances: [instances.second.id] }
        expect(user).to have_role(:member, instances.second)
        expect(user).not_to have_role(:member, instances.first)
      end
      it "changes the active instance if the active instance is removed" do
        put :update, id: user.id, user: { instances: [instances.second.id] }
        expect(user.reload.active_instance).to eq instances.second
      end
      it "removes the active instance if all instances are removed" do
        put :update, id: user.id, user: { instances: [] }
        expect(user.reload.active_instance).to be_nil
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
          expect(user).to have_role(:member, instances.second)
        end
        it "changes the active instance if the active instance is removed" do
          put :update, id: user.id, user: { instances: [instances.second.id] }
          expect(user.reload.active_instance).to eq instances.second
        end
        it "removes the active instance if all instances are removed" do
          put :update, id: user.id, user: { instances: [] }
          expect(user.reload.active_instance).to be_nil
        end
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
  end
end
