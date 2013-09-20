require 'spec_helper'

describe InstancesController do
  login_user(:admin)

  let(:instance) { create(:instance) }

  describe "GET #index" do
    let!(:instances) { create_list(:instance, 2) }

    it "lists instances" do
      get :index
      response.should be_successful
      assigns(:instances).should match_array(instances)
    end

    it "lists instances via xhr" do
      xhr :get, :index
      response.should be_successful
      response.should render_template("_list")
    end
  end

  describe "POST #select" do
    it "sets the current user's active instance" do
      logged_in_user.active_instance.should be_nil
      post :select, id: instance.id

      response.should redirect_to(root_url())
      logged_in_user.reload.active_instance.should == instance
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: instance.id
      response.should be_success
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new
      response.should be_success
    end
  end
  describe "POST #create" do
    it "redirects to the instance when successful" do
      post :create, instance: valid_parameters_for(:instance)
      response.should redirect_to(assigns(:instance))
    end
    it "renders the new view when validation fails" do
      post :create, instance: invalid_parameters_for(:instance)
      response.should render_template("new")
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: instance.id
      response.should be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the instance when successful" do
      new_name = "#{instance.name} updated" 
      put :update, id: instance.id, instance: { name: new_name }
      response.should redirect_to(instance)
      instance.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: instance.id, instance: invalid_parameters_for(:instance)
      response.should render_template("edit")
    end
  end
end
