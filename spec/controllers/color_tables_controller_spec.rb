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
      response.status.should == 404
    end
    it "disallows suite color tables with the wrong instance" do
      suite = create(:suite, instance: instance)
      get :show, id: suite.color_table.id
      response.status.should == 404
    end
  end

  
  describe "GET #index" do
    let!(:regular)         { create_list(:color_table, 2) }
    let!(:suite)           { create_list(:suite,       2).collect(&:color_table) }
    let!(:other_instances) { [ other_instance ]}

    it "lists regular" do
      get :index
      response.should be_success
      assigns(:color_tables).should match_array(regular)
    end
    it "is filterable" do
      get :index, q: { name_cont: regular.first.name}
      response.should be_success
      assigns(:color_tables).should == [regular.first]
    end

    context "with a regular user" do
      login_user(:user)

      let(:edited)  { create(:color_table) }
      let(:managed) { create(:color_table) }

      before(:each) do
        logged_in_user.add_role :reader,  regular.first
        logged_in_user.add_role :editor,  edited
        logged_in_user.add_role :manager, managed
      end

      it "lists regular suites accessible by the user" do
        get :index
        response.should be_success
        assigns(:color_tables).should match_array([
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
      response.should be_success
      response.should render_template("layouts/fullpage")
    end
    it "gives a 404 if the instance does not match" do
      get :show, id: other_instance.id
      response.status.should == 404
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new
      response.should be_success
    end
  end
  describe "POST #create" do
    let(:evaluations) { [
      create(:generic_evaluation),
      create(:suite_evaluation)
    ] }
    it "creates a color table" do
      post :create, color_table: valid_parameters_for(:color_table)
      response.should redirect_to(ColorTable.last)
    end
    it "renders the new action if the suite is invalid" do
      post :create, color_table: invalid_parameters_for(:color_table)
      response.should render_template("new")
    end
    it "sets the instance from the current user's active instance" do
      post :create, color_table: valid_parameters_for(:color_table).merge(instance_id: instance.id)
      assigns(:color_table).instance.should_not == instance
      assigns(:color_table).instance.should     == logged_in_user.active_instance
    end
    it "supports assigning evaluations by a list of comma separated ids" do
      post :create, color_table: valid_parameters_for(:color_table).merge(evaluation_ids: evaluations.collect(&:id).join(","))
      assigns(:color_table).evaluations.should match_array(evaluations)
    end
    it "grants manager privileges to the creator" do
      post :create, color_table: valid_parameters_for(:color_table)
      logged_in_user.should have_role(:manager, assigns(:color_table))
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: color_table.id
      response.should be_success
    end
    it "gives a 404 if the instance does not match" do
      get :edit, id: other_instance.id
      response.status.should == 404
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
      response.should redirect_to(color_table)
      color_table.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: color_table.id, color_table: invalid_parameters_for(:color_table)
      response.should render_template("edit")
    end
    it "gives a 404 if the instance does not match" do
      put :update, id: other_instance.id, color_table: {}
      response.status.should == 404
    end
    it "prevents changing the instance" do
      put :update, id: color_table.id, color_table: { instance_id: instance.id }
      color_table.reload.instance.should_not == instance
    end
    it "supports assigning evaluations by a list of comma separated ids" do
      put :update, id: color_table.id, color_table: { evaluation_ids: evaluations.collect(&:id).join(",") }
      color_table.reload.evaluations(true).should match_array(evaluations)
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: color_table.id
      response.should be_success
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_destroy, id: other_instance.id
      response.status.should == 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the color_table list page" do
      delete :destroy, id: color_table.id
      response.should redirect_to(color_tables_url())
      ColorTable.exists?(color_table.id).should be_false
    end
    it "gives a 404 if the instance does not match" do
      delete :destroy, id: other_instance.id
      response.status.should == 404
    end
  end

  describe "PUT #save_state" do
    it "sets the requested table state as the current user's setting for the color_table" do
     updated_at = color_table.updated_at
     put :save_state, id: color_table.id, state: '{"foo": "bar"}'

     response.should be_success
     logged_in_user.settings.for(color_table).first.data["datatable_state"].should == { "foo" => "bar" }

     Timecop.freeze(Time.now + 5.minutes) do
       updated_at.should < color_table.reload.updated_at 
     end
    end
    it "gives a 404 if the instance does not match" do
      put :save_state, id: other_instance.id, state: '{"foo": "bar"}'
      response.status.should == 404
    end

    context "with existing data" do
      before(:each) do
        logged_in_user.settings.create(customizable: color_table, data: { "datatable_state" => { "bar" => "baz" }, "zomg" => "lol" })
      end
      it "overrides the datatable state, and leaves the other data alone" do
        put :save_state, id: color_table.id, state: '{"foo": "bar"}'
        response.should be_success

        data = logged_in_user.settings.for(color_table).first.data
        data["datatable_state"].should == { "foo" => "bar" }
        data["zomg"].should            == "lol"
      end
    end
  end

  describe "GET #clear_state" do
    before(:each) do
      logged_in_user.settings.create(customizable: color_table, data: { "datatable_state" => { "bar" => "baz" }, "zomg" => "lol" })
    end
    it "removes the datatable setting" do
      get :clear_state, id: color_table.id
      response.should redirect_to(color_table)

      data = logged_in_user.settings.for(color_table).first.data
      data["datatable_state"].should be_nil
      data["zomg"].should            == "lol"
    end
    it "gives a 404 if the instance does not match" do
      get :clear_state, id: other_instance.id
      response.status.should == 404
    end
  end

  describe "PUT #add_student_data" do
    it "adds a student data key to the suite" do
      color_table.student_data.should be_blank

      put :add_student_data, id: color_table.id, key: "foo"
      response.should redirect_to(color_table)
      color_table.reload.student_data.should include("foo")
    end
    it "gives a 404 if the instance does not match" do
      put :add_student_data, id: other_instance.id, key: "foo"
      response.status.should == 404
    end
  end
end
