require 'spec_helper'

describe SuitesController do
  login_user(:admin)

  let(:instance)    { create(:instance) }
  let(:suite)       { create(:suite) }
  let(:other_suite) { create(:suite, instance: instance) }

  describe "GET #index" do
    let!(:regular_suites)  { create_list(:suite, 2) }
    let!(:template_suites) { create_list(:suite, 2, is_template: true) }
    let!(:other_instance)  { other_suite }

    it "lists regular suites" do
      get :index
      response.should be_success
      assigns(:suites).should match_array(regular_suites)
    end
    it "is filterable" do
      get :index, q: { name_cont: regular_suites.first.name}
      response.should be_success
      assigns(:suites).should == [regular_suites.first]
    end

    context "with a regular user" do
      login_user(:user)

      before(:each) do
        logged_in_user.grant :suite_contributor, regular_suites.first
        logged_in_user.grant :suite_contributor, other_instance
      end

      it "lists regular suites accessible by the user" do
        get :index
        response.should be_success
        assigns(:suites).should == [regular_suites.first]
      end
    end
  end

  describe "GET #search_participants" do
    let(:group)        { create(:group) }
    let(:student)      { create(:student,     groups: [group]) }
    let!(:participant) { create(:participant, suite:  suite,   student: student) }

    it "searches suite participant students and groups" do
      get :search_participants, id: suite.id, gq: { name_cont: group.name }, sq: { last_name_cont: student.last_name }

      response.should be_success
      json = JSON.parse(response.body)

      json["more"].should be_false

      json["results"].should        have(2).items
      json["results"].first.should  include("id"   => "s-#{student.id}")
      json["results"].first.should  include("text" => student.name)
      json["results"].second.should include("id"   => "g-#{group.id}")
      json["results"].second.should include("text" => group.name)
    end
    it "gives a 404 if the instance does not match" do
      suite.instance = instance
      suite.save!

      get :search_participants, id: suite.id, gq: { name_cont: group.name }, sq: { last_name_cont: student.last_name }
      response.status.should == 404
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: suite.id
      response.should be_success
    end
    it "gives a 404 if the instance does not match" do
      get :show, id: other_suite.id
      response.status.should == 404
    end
  end

  describe "GET #color_table" do
    let(:generic_evaluations)       { create_list(:generic_evaluation, 2) }
    let!(:other_generic_evaluation) { create(     :generic_evaluation, instance: instance) }
    before(:each) do
      suite.generic_evaluations << generic_evaluations.first.id
      suite.save
    end

    it "partitions generic evaluations depending on their inclusion in the suite" do
      get :color_table, id: suite.id
      response.should be_success
      response.should render_template("layouts/fullpage")
      assigns(:generic_evaluations)[:included].should == [generic_evaluations.first]
      assigns(:generic_evaluations)[:missing].should  == [generic_evaluations.last]
    end
    it "gives a 404 if the instance does not match" do
      get :color_table, id: other_suite.id
      response.status.should == 404
    end
  end

  describe "PUT #save_color_table_state" do
    it "sets the requested table state as the current user's setting for the suite" do
      put :save_color_table_state, id: suite.id, state: '{"foo": "bar"}'
      response.should be_success

      logged_in_user.settings.for(suite).first.data["datatable_state"].should == { "foo" => "bar" }
    end
    it "gives a 404 if the instance does not match" do
      put :save_color_table_state, id: other_suite.id, state: '{"foo": "bar"}'
      response.status.should == 404
    end

    context "with existing data" do
      before(:each) do
        logged_in_user.settings.create(customizable: suite, data: { "datatable_state" => { "bar" => "baz" }, "zomg" => "lol" })
      end
      it "overrides the datatable state, and leaves the other data alone" do
        put :save_color_table_state, id: suite.id, state: '{"foo": "bar"}'
        response.should be_success

        data = logged_in_user.settings.for(suite).first.data
        data["datatable_state"].should == { "foo" => "bar" }
        data["zomg"].should            == "lol"
      end
    end
  end

  describe "GET #clear_color_table_state" do
    before(:each) do
      logged_in_user.settings.create(customizable: suite, data: { "datatable_state" => { "bar" => "baz" }, "zomg" => "lol" })
    end
    it "removes the datatable setting" do
      get :clear_color_table_state, id: suite.id
      response.should redirect_to(color_table_suite_url(suite))

      data = logged_in_user.settings.for(suite).first.data
      data["datatable_state"].should be_nil
      data["zomg"].should            == "lol"
    end
    it "gives a 404 if the instance does not match" do
      get :clear_color_table_state, id: other_suite.id
      response.status.should == 404
    end
  end

  describe "GET #new" do
    it "builds a suite" do
      get :new
      response.should be_success
      assigns(:suite).participants.should have(1).item
    end
  end
  describe "POST #new_from_template" do
    let(:template) { create(:suite, is_template: true) }
    it "builds an evaluation from a template" do
      post :new_from_template, suite: { template_id: template.id }
      response.should be_success
      assigns(:suite).template_id.should == template.id
      assigns(:suite).participants.should have(1).item
    end
    it "gives a 404 if the instance does not match" do
      template = create(:suite, is_template: true, instance: instance)
      post :new_from_template, suite: { template_id: template.id }
      response.status.should == 404
    end
  end
  describe "POST #create" do
    let(:students) { create_list(:student, 3) }
    let(:groups)   { create_list(:group, 2) }

    let(:student_ids) { students.collect(&:id).join(",") }
    let(:group_ids)   { groups.collect(&:id).join(",") }

    before(:each) do
      groups.first.students  << students.first
      groups.second.students << students.second
    end

    it "creates participants from autocomplete data" do
      post :create,
        suite: {
          name: "Test suite",
          is_template: "0",
          instance_id: logged_in_user.active_instance.id,
          participants_attributes: {
            "0" => {
              :student_id => student_ids,
              :group_id => group_ids
            }
          }
        }

      response.should redirect_to(Suite.last)
      Suite.last.participants.collect(&:student).should match_array(students)
    end
    it "does not create participants when the suite is a template" do
      post :create,
        suite: {
          name: "Test suite",
          is_template: "1",
          instance_id: logged_in_user.active_instance.id,
          participants_attributes: {
            "0" => {
              :student_id => student_ids,
              :group_id => group_ids
            }
          }
        }

      response.should redirect_to(Suite.last)
      Suite.last.participants.should be_empty
    end
    it "renders the new action if the suite is invalid" do
      post :create, suite: invalid_parameters_for(:suite)
      response.should render_template("new")
    end
    it "sets the instance from the current user's active instance" do
      post :create, suite: valid_parameters_for(:suite).merge(instance_id: instance.id)
      assigns(:suite).instance.should_not == instance
      assigns(:suite).instance.should     == logged_in_user.active_instance
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: suite.id
      response.should be_success
    end
    it "gives a 404 if the instance does not match" do
      get :edit, id: other_suite.id
      response.status.should == 404
    end
  end
  describe "PUT #update" do
    it "redirects to the suite when successful" do
      new_name = "#{suite.name} updated" 
      put :update, id: suite.id, suite: { name: new_name }
      response.should redirect_to(suite)
      suite.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: suite.id, suite: invalid_parameters_for(:suite)
      response.should render_template("edit")
    end
    it "gives a 404 if the instance does not match" do
      put :update, id: other_suite.id, suite: {}
      response.status.should == 404
    end
    it "prevents changing the instance" do
      put :update, id: suite.id, suite: { instance_id: instance.id }
      suite.reload.instance.should_not == instance
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: suite.id
      response.should be_success
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_destroy, id: other_suite.id
      response.status.should == 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the suite list page" do
      delete :destroy, id: suite.id
      response.should redirect_to(suites_url())
      Suite.exists?(suite.id).should be_false
    end
    it "redirects to the suite template list page when deleting templates" do
      suite.is_template = true
      suite.save!

      delete :destroy, id: suite.id
      response.should redirect_to(template_suites_url())
      Suite.exists?(suite.id).should be_false
    end
    it "gives a 404 if the instance does not match" do
      delete :destroy, id: other_suite.id
      response.status.should == 404
    end
  end

  describe "GET #select_users" do
    it "is successful" do
      get :select_users, id: suite.id
      response.should be_success
    end
    it "gives a 404 if the instance does not match" do
      get :select_users, id: other_suite.id
      response.status.should == 404
    end
  end
  describe "PUT #add_users" do
    let(:users) { create_list(:user, 2) }

    it "gives the users suite_contributor privileges for the suite" do
      users.first.has_role?(:suite_contributor, suite).should be_false
      users.second.has_role?(:suite_contributor, suite).should be_false

      put :add_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
      response.should redirect_to(suite)

      users.first.has_role?(:suite_contributor, suite).should be_true
      users.second.has_role?(:suite_contributor, suite).should be_true
    end
    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        put :add_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
        updated_at.should < suite.reload.updated_at
      end
    end
    it "gives a 404 if the instance does not match" do
      put :add_users, id: other_suite.id, suite: { user_id: users.collect(&:id).join(",") }
      response.status.should == 404
    end
  end
  describe "DELETE #remove_users" do
    let(:users) { create_list(:user, 2) }

    it "removes the users' suite_contributor privileges for the suite" do
      users.each { |u| u.add_role :suite_contributor, suite }

      users.first.has_role?(:suite_contributor, suite).should be_true
      users.second.has_role?(:suite_contributor, suite).should be_true

      delete :remove_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
      response.should redirect_to(suite)

      users.first.has_role?(:suite_contributor, suite).should be_false
      users.second.has_role?(:suite_contributor, suite).should be_false
    end
    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        delete :remove_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
        updated_at.should < suite.reload.updated_at
      end
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_users, id: other_suite.id, suite: { user_id: users.collect(&:id).join(",") }
      response.status.should == 404
    end
  end

  describe "PUT #add_generic_evaluations" do
    let(:evaluation)       { create(:generic_evaluation) }
    let(:other_evaluation) { create(:generic_evaluation, instance: instance) }

    it "adds the generic evaluations to the suite" do
      put :add_generic_evaluations, id: suite.id, suite: { generic_evaluations: evaluation.id }
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.generic_evaluations.should include(evaluation.id)
    end
    it "gives a 404 if the instance does not match" do
      put :add_generic_evaluations, id: other_suite.id, suite: { generic_evaluations: evaluation.id }
      response.status.should == 404
    end
    it "gives a 404 if the evaluation's instance does not match" do
      put :add_generic_evaluations, id: suite.id, suite: { generic_evaluations: other_evaluation.id }
      response.status.should == 404
    end
  end
  describe "DELETE #remove_generic_evaluations" do
    let(:evaluation)       { create(:generic_evaluation) }
    let(:other_evaluation) { create(:generic_evaluation, instance: instance) }

    it "removes the generic evaluations from the suite" do
      suite.generic_evaluations << evaluation.id
      suite.save

      delete :remove_generic_evaluations, id: suite.id, evaluation_id: evaluation.id
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.generic_evaluations.should_not include(evaluation.id)
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_generic_evaluations, id: other_suite.id, evaluation_id: evaluation.id
      response.status.should == 404
    end
    it "gives a 404 if the evaluation's instance does not match" do
      delete :remove_generic_evaluations, id: suite.id, evaluation_id: other_evaluation.id
      response.status.should == 404
    end
  end

  describe "PUT #add_student_data" do
    it "adds a student data key to the suite" do
      suite.student_data.should be_blank

      put :add_student_data, id: suite.id, key: "foo"
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.student_data.should include("foo")
    end
    it "gives a 404 if the instance does not match" do
      put :add_student_data, id: other_suite.id, key: "foo"
      response.status.should == 404
    end
  end
  describe "PUT #add_student_data" do
    it "removes a student data key from the suite" do
      suite.student_data << "foo"
      suite.save

      delete :remove_student_data, id: suite.id, key: "foo"
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.student_data.should_not include("foo")
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_student_data, id: other_suite.id, key: "foo"
      response.status.should == 404
    end
  end
end
