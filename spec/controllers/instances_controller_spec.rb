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
  end
end
