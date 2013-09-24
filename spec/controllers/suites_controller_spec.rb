require 'spec_helper'

describe SuitesController do
  login_user(:admin)

  let(:suite) { create(:suite) }

  describe "GET #index" do
    let!(:regular_suites)  { create_list(:suite, 2) }
    let!(:template_suites) { create_list(:suite, 2, is_template: true) }

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
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: suite.id
      response.should be_success
    end
  end

  describe "GET #color_table" do
    let(:generic_evaluations) { create_list(:generic_evaluation, 2) }
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
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: suite.id
      response.should be_success
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
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: suite.id
      response.should be_success
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
  end

  describe "GET #select_users" do
    it "is successful" do
      get :select_users, id: suite.id
      response.should be_success
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
  end

  describe "PUT #add_generic_evaluations" do
    let(:evaluation) { create(:generic_evaluation) }
    it "adds the generic evaluations to the suite" do
      put :add_generic_evaluations, id: suite.id, suite: { generic_evaluations: evaluation.id }
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.generic_evaluations.should include(evaluation.id)
    end
  end
  describe "DELETE #remove_generic_evaluations" do
    let(:evaluation) { create(:generic_evaluation) }
    it "removes the generic evaluations from the suite" do
      suite.generic_evaluations << evaluation.id
      suite.save

      delete :remove_generic_evaluations, id: suite.id, evaluation_id: evaluation.id
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.generic_evaluations.should_not include(evaluation.id)
    end
  end

  describe "PUT #add_student_data" do
    it "adds a student data key to the suite" do
      suite.student_data.should be_blank

      put :add_student_data, id: suite.id, key: "foo"
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.student_data.should include("foo")
    end
  end
  describe "PUT #add_student_data" do
    it "fremoves a student data key from the suite" do
      suite.student_data << "foo"
      suite.save

      delete :remove_student_data, id: suite.id, key: "foo"
      response.should redirect_to(color_table_suite_url(suite))
      suite.reload.student_data.should_not include("foo")
    end
  end
end
