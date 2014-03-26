require 'spec_helper'

describe TableStatesController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:color_table)       { create(:color_table) }
  let(:table_state)       { create(:table_state, base: color_table, data: { foo: "bar" }) }
  let(:instance)          { create(:instance) }
  let(:other_color_table) { create(:color_table, instance: instance) }
  let(:other_table_state) { create(:table_state, base: other_color_table, data: { foo: "bar" }) }

  describe "GET #show" do
    it "is successful" do
      get :show, id: table_state.id

      expect(response).to be_success

      json = JSON.parse(response.body)
      expect(json["foo"]).to eq "bar"
    end
    it "gives a 404 if the base's instance does not match" do
      get :show, id: other_table_state.id
      expect(response.status).to be 404
    end

    context "with suite color table" do
      let(:color_table)       { create(:suite).color_table }
      let(:table_state)       { create(:table_state, base: color_table, data: { foo: "bar" }) }
      let(:other_color_table) { create(:suite, instance: instance).color_table }
      let(:other_table_state) { create(:table_state, base: other_color_table, data: { foo: "bar" }) }

      it "is successful when the suite's instance matches" do
        get :show, id: table_state.id
        expect(response).to be_success
      end
      it "gives a 404 if the suite's instance does not match" do
        get :show, id: other_table_state.id
        expect(response.status).to be 404
      end
    end
  end

  describe "GET #select" do
    it "sets the requested table state as the current user's setting for the base" do
      get :select, id: table_state.id
      expect(response).to redirect_to(color_table)

      expect(logged_in_user.settings.for(color_table).first.data["datatable_state"]).to eq({ "foo" => "bar" })
    end
    it "gives a 404 if the base's instance does not match" do
      get :select, id: other_table_state.id
      expect(response.status).to be 404
    end

    context "with existing data" do
      before(:each) do
        logged_in_user.settings.create(
          customizable: color_table,
          data: { "datatable_state" => { "bar" => "baz" }, "zomg" => "lol" }
        )
      end
      it "overrides the datatable state, and leaves the other data alone" do
        get :select, id: table_state.id
        expect(response).to redirect_to(color_table)

        data = logged_in_user.settings.for(color_table).first.data
        expect(data["datatable_state"]).to eq({ "foo" => "bar" })
        expect(data["zomg"]).to            eq "lol"
      end
    end
  end

  describe "POST #create" do
    it "is successful when valid" do
      post :create, color_table_id: color_table.id, table_state: valid_parameters_for(:table_state)

      expect(response).to be_success

      json  = JSON.parse(response.body)
      state = TableState.find(TableState.maximum("id"))

      expect(json["id"]).to              eq state.id
      expect(json["name"]).to            eq state.name
      expect(json["urls"]["default"]).to eq table_state_path(state)
      expect(json["urls"]["select"]).to  eq select_table_state_path(state)

      expect(state.base_id).to eq color_table.id
    end
    it "is returns an error when invalid" do
      post :create, color_table_id: color_table.id, table_state: invalid_parameters_for(:table_state)

      expect(response.status).to be 400

      json = JSON.parse(response.body)
      expect(json["errors"]).not_to be_blank
    end
    it "updates an existing state if the name and base already exists" do
      post :create, color_table_id: color_table.id, table_state: { name: table_state.name, data: '{"zomg":"lol"}' }
      expect(response).to be_success

      expect(table_state.reload.data).to eq({ "zomg" => "lol" })
    end
    it "gives a 404 if the base's instance does not match" do
      post :create, color_table_id: other_color_table.id, table_state: valid_parameters_for(:table_state)
      expect(response.status).to be 404
    end
  end

  describe "PUT #update" do
    it "is successful when valid" do
      new_name = "#{table_state.name} updated"
      put :update, id: table_state.id, table_state: { name: new_name }

      expect(response).to be_success

      json = JSON.parse(response.body)
      expect(json["id"]).to              eq table_state.id
      expect(json["name"]).to            eq new_name
      expect(table_state.reload.name).to eq new_name
    end
    it "is returns an error when invalid" do
      put :update, id: table_state.id, table_state: { name: "" }

      expect(response.status).to be 400

      json = JSON.parse(response.body)
      expect(json["errors"]).not_to be_blank
    end
    it "gives a 404 if the base's instance does not match" do
      put :update, id: other_table_state.id, table_state: {}
      expect(response.status).to be 404
    end
  end

  describe "DELETE #destroy" do
    it "destroys the object" do
      delete :destroy, id: table_state.id
      expect(response).to be_success
      expect(TableState.where(id: table_state.id).first).to be_nil
    end
    it "gives a 404 if the base's instance does not match" do
      delete :destroy, id: other_table_state.id
      expect(response.status).to be 404
    end
  end
end
