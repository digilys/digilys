require 'spec_helper'

describe TableStatesController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:suite)             { create(:suite) }
  let(:table_state)       { create(:table_state, base: suite, data: { foo: "bar" }) }
  let(:instance)          { create(:instance) }
  let(:other_suite)       { create(:suite, instance: instance) }
  let(:other_table_state) { create(:table_state, base: other_suite, data: { foo: "bar" }) }

  describe "GET #show" do
    it "is successful" do
      get :show, id: table_state.id

      response.should    be_success

      json               = JSON.parse(response.body)
      json["foo"].should == "bar"
    end
    it "gives a 404 if the base's instance does not match" do
      get :show, id: other_table_state.id
      response.status.should == 404
    end
  end

  describe "GET #select" do
    it "sets the requested table state as the current user's setting for the base" do
      get :select, id: table_state.id
      response.should redirect_to(color_table_suite_url(suite))

      logged_in_user.settings.for(suite).first.data["datatable_state"].should == { "foo" => "bar" }
    end
    it "gives a 404 if the base's instance does not match" do
      get :select, id: other_table_state.id
      response.status.should == 404
    end

    context "with existing data" do
      before(:each) do
        logged_in_user.settings.create(customizable: suite, data: { "datatable_state" => { "bar" => "baz" }, "zomg" => "lol" })
      end
      it "overrides the datatable state, and leaves the other data alone" do
        get :select, id: table_state.id
        response.should redirect_to(color_table_suite_url(suite))

        data = logged_in_user.settings.for(suite).first.data
        data["datatable_state"].should == { "foo" => "bar" }
        data["zomg"].should            == "lol"
      end
    end
  end

  describe "POST #create" do
    it "is successful when valid" do
      post :create, suite_id: suite.id, table_state: valid_parameters_for(:table_state)

      response.should   be_success

      json  = JSON.parse(response.body)
      state = TableState.find(TableState.maximum("id"))

      json["id"].should              == state.id
      json["name"].should            == state.name
      json["urls"]["default"].should == table_state_path(state)
      json["urls"]["select"].should  == select_table_state_path(state)

      state.base_id.should == suite.id
    end
    it "is returns an error when invalid" do
      post :create, suite_id: suite.id, table_state: invalid_parameters_for(:table_state)

      response.status.should    == 400

      json                      = JSON.parse(response.body)
      json["errors"].should_not be_blank
    end
    it "updates an existing state if the name and base already exists" do
      post :create, suite_id: suite.id, table_state: { name: table_state.name, data: '{"zomg":"lol"}' }
      response.should be_success

      table_state.reload.data.should == { "zomg" => "lol" }
    end
    it "gives a 404 if the base's instance does not match" do
      post :create, suite_id: other_suite.id, table_state: valid_parameters_for(:table_state)
      response.status.should == 404
    end
  end

  describe "PUT #update" do
    it "is successful when valid" do
      new_name = "#{table_state.name} updated"
      put :update, id: table_state.id, table_state: { name: new_name }

      response.should                be_success

      json                           = JSON.parse(response.body)
      json["id"].should              == table_state.id
      json["name"].should            == new_name
      table_state.reload.name.should == new_name
    end
    it "is returns an error when invalid" do
      put :update, id: table_state.id, table_state: { name: "" }

      response.status.should    == 400

      json                      = JSON.parse(response.body)
      json["errors"].should_not be_blank
    end
    it "gives a 404 if the base's instance does not match" do
      put :update, id: other_table_state.id, table_state: {}
      response.status.should == 404
    end
  end

  describe "DELETE #destroy" do
    it "destroys the object" do
      delete :destroy, id: table_state.id
      response.should be_success
      TableState.where(id: table_state.id).first.should be_nil
    end
    it "gives a 404 if the base's instance does not match" do
      delete :destroy, id: other_table_state.id
      response.status.should == 404
    end
  end
end
