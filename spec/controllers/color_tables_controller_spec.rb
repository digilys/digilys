require 'spec_helper'

describe ColorTablesController do
  login_user(:admin)

  let(:color_table)       { create(:color_table) }
  let(:suite_color_table) { create(:suite).color_table }
  let(:instance)          { create(:instance) }
  let(:other_instance)    { create(:color_table, instance: instance) }

  describe "#instance_filter" do
    it "disallows color tables with the wrong instance" do
      get :show, id: create(:color_table, instance: instance).id
      expect(response.status).to be 404
    end
    it "disallows suite color tables with the wrong instance" do
      suite = create(:suite, instance: instance)
      get :show, id: suite.color_table.id
      expect(response.status).to be 404
    end
  end

  
  describe "GET #index" do
    let!(:regular)         { create_list(:color_table, 2) }
    let!(:suite)           { create_list(:suite,       2).collect(&:color_table) }
    let!(:other_instances) { [ other_instance ]}

    it "lists regular" do
      get :index
      expect(response).to be_success
      expect(assigns(:color_tables)).to match_array(regular)
    end
    it "is filterable" do
      get :index, q: { name_cont: regular.first.name}
      expect(response).to be_success
      expect(assigns(:color_tables)).to eq [regular.first]
    end

    context "with a regular user" do
      login_user(:user)

      let(:edited)  { create(:color_table) }
      let(:managed) { create(:color_table) }

      before(:each) do
        logged_in_user.add_role :reader,  regular.first
        logged_in_user.add_role :reader,  edited
        logged_in_user.add_role :editor,  edited
        logged_in_user.add_role :manager, managed
      end

      it "lists regular suites accessible by the user" do
        get :index
        expect(response).to be_success
        expect(assigns(:color_tables)).to match_array([
          regular.first,
          edited,
          managed
        ])
      end
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: color_table.id
      expect(response).to be_success
      expect(response).to render_template("layouts/fullpage")
    end
    it "gives a 404 if the instance does not match" do
      get :show, id: other_instance.id
      expect(response.status).to be 404
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new
      expect(response).to be_success
    end
  end
  describe "POST #create" do
    let(:evaluations) { [
      create(:generic_evaluation),
      create(:suite_evaluation)
    ] }
    it "creates a color table" do
      post :create, color_table: valid_parameters_for(:color_table)
      expect(response).to redirect_to(ColorTable.last)
    end
    it "renders the new action if the suite is invalid" do
      post :create, color_table: invalid_parameters_for(:color_table)
      expect(response).to render_template("new")
    end
    it "sets the instance from the current user's active instance" do
      post :create, color_table: valid_parameters_for(:color_table).merge(instance_id: instance.id)
      expect(assigns(:color_table).instance).not_to eq instance
      expect(assigns(:color_table).instance).to     eq logged_in_user.active_instance
    end
    it "supports assigning evaluations by a list of comma separated ids" do
      post :create, color_table: valid_parameters_for(:color_table).merge(evaluation_ids: evaluations.collect(&:id).join(","))
      expect(assigns(:color_table).evaluations).to match_array(evaluations)
    end
    it "grants manager privileges to the creator" do
      post :create, color_table: valid_parameters_for(:color_table)
      expect(logged_in_user).to have_role(:manager, assigns(:color_table))
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: color_table.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :edit, id: other_instance.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #update" do
    let(:evaluations) { [
      create(:generic_evaluation),
      create(:suite_evaluation)
    ] }
    it "redirects to the color table when successful" do
      new_name = "#{color_table.name} updated" 
      put :update, id: color_table.id, color_table: { name: new_name }
      expect(response).to redirect_to(color_table)
      expect(color_table.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: color_table.id, color_table: invalid_parameters_for(:color_table)
      expect(response).to render_template("edit")
    end
    it "gives a 404 if the instance does not match" do
      put :update, id: other_instance.id, color_table: {}
      expect(response.status).to be 404
    end
    it "prevents changing the instance" do
      put :update, id: color_table.id, color_table: { instance_id: instance.id }
      expect(color_table.reload.instance).not_to eq instance
    end
    it "supports assigning evaluations by a list of comma separated ids" do
      put :update, id: color_table.id, color_table: { evaluation_ids: evaluations.collect(&:id).join(",") }
      expect(color_table.reload.evaluations(true)).to match_array(evaluations)
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: color_table.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_destroy, id: other_instance.id
      expect(response.status).to be 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the color_table list page" do
      delete :destroy, id: color_table.id
      expect(response).to redirect_to(color_tables_url())
      expect(ColorTable.exists?(color_table.id)).to be_false
    end
    it "gives a 404 if the instance does not match" do
      delete :destroy, id: other_instance.id
      expect(response.status).to be 404
    end
  end

  describe "PUT #save_state" do
    it "sets the requested table state as the current user's setting for the color_table" do
     put :save_state, id: color_table.id, state: '{"foo": "bar"}'
     expect(response).to be_success
     expect(logged_in_user.settings.for(color_table).first.data["color_table_state"]).to eq({ "foo" => "bar" })
    end
    it "gives a 404 if the instance does not match" do
      put :save_state, id: other_instance.id, state: '{"foo": "bar"}'
      expect(response.status).to be 404
    end

    context "with existing data" do
      before(:each) do
        logged_in_user.settings.create(customizable: color_table, data: { "color_table_state" => { "bar" => "baz" }, "zomg" => "lol" })
      end
      it "overrides the datatable state, and leaves the other data alone" do
        put :save_state, id: color_table.id, state: '{"foo": "bar"}'
        expect(response).to be_success

        data = logged_in_user.settings.for(color_table).first.data
        expect(data["color_table_state"]).to eq({ "foo" => "bar" })
        expect(data["zomg"]).to            eq "lol"
      end
    end
  end

  describe "GET #clear_state" do
    before(:each) do
      logged_in_user.settings.create(customizable: color_table, data: { "color_table_state" => { "bar" => "baz" }, "zomg" => "lol" })
    end
    it "removes the datatable setting" do
      get :clear_state, id: color_table.id
      expect(response).to redirect_to(color_table)

      data = logged_in_user.settings.for(color_table).first.data
      expect(data["color_table_state"]).to be_nil
      expect(data["zomg"]).to            eq "lol"
    end
    it "gives a 404 if the instance does not match" do
      get :clear_state, id: other_instance.id
      expect(response.status).to be 404
    end
  end

  describe "PUT #add_student_data" do
    it "adds a student data key to the suite" do
      expect(color_table.student_data).to be_blank

      put :add_student_data, id: color_table.id, key: "foo"
      expect(response).to redirect_to(color_table)
      expect(color_table.reload.student_data).to include("foo")
    end
    it "gives a 404 if the instance does not match" do
      put :add_student_data, id: other_instance.id, key: "foo"
      expect(response.status).to be 404
    end
  end
end
