require 'spec_helper'

describe SuitesController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance)    { create(:instance) }
  let(:suite)       { create(:suite) }
  let(:other_suite) { create(:suite, instance: instance) }

  describe "GET #index" do
    let!(:regular_suites)  { create_list(:suite, 2) }
    let!(:template_suites) { create_list(:suite, 2, is_template: true) }
    let!(:other_instance)  { other_suite }
    let!(:closed_suite)    { create(:suite, status: :closed) }

    it "lists regular, open suites" do
      get :index
      expect(response).to be_success
      expect(assigns(:suites)).to match_array(regular_suites)
    end
    it "is filterable" do
      get :index, q: { name_cont: regular_suites.first.name}
      expect(response).to be_success
      expect(assigns(:suites)).to eq [regular_suites.first]
    end

    context "with a regular user" do
      login_user(:user)

      before(:each) do
        logged_in_user.grant :suite_member, regular_suites.first
        logged_in_user.grant :suite_member, other_instance
        logged_in_user.grant :suite_member, closed_suite
      end

      it "lists regular suites accessible by the user" do
        get :index
        expect(response).to be_success
        expect(assigns(:suites)).to eq [regular_suites.first]
      end
    end
  end

  describe "GET #closed" do
    let!(:regular_suites)  { create_list(:suite, 2, status: :closed) }
    let!(:template_suites) { create_list(:suite, 2, is_template: true, status: :closed) }
    let!(:other_instance)  { create(:suite, status: :closed, instance: instance) }
    let!(:open_suite)    { create(:suite, status: :open) }

    it "lists regular, open suites" do
      get :closed
      expect(response).to be_success
      expect(assigns(:suites)).to match_array(regular_suites)
    end
    it "is filterable" do
      get :closed, q: { name_cont: regular_suites.first.name}
      expect(response).to be_success
      expect(assigns(:suites)).to eq [regular_suites.first]
    end

    context "with a regular user" do
      login_user(:user)

      before(:each) do
        logged_in_user.grant :suite_member, regular_suites.first
        logged_in_user.grant :suite_member, other_instance
        logged_in_user.grant :suite_member, open_suite
      end

      it "lists regular suites accessible by the user" do
        get :closed
        expect(response).to be_success
        expect(assigns(:suites)).to eq [regular_suites.first]
      end
    end
  end

  describe "GET #search_participants" do
    let(:group)        { create(:group) }
    let(:student)      { create(:student,     groups: [group]) }
    let!(:participant) { create(:participant, suite:  suite,   student: student) }

    it "searches suite participant students and groups" do
      get :search_participants, id: suite.id, gq: { name_cont: group.name }, sq: { last_name_cont: student.last_name }

      expect(response).to be_success
      json = JSON.parse(response.body)

      expect(json["more"]).to be_false

      expect(json["results"]).to        have(2).items
      expect(json["results"].first).to  include("id"   => "s-#{student.id}")
      expect(json["results"].first).to  include("text" => student.name)
      expect(json["results"].second).to include("id"   => "g-#{group.id}")
      expect(json["results"].second).to include("text" => group.name)
    end
    it "gives a 404 if the instance does not match" do
      suite.instance = instance
      suite.save!

      get :search_participants, id: suite.id, gq: { name_cont: group.name }, sq: { last_name_cont: student.last_name }
      expect(response.status).to be 404
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: suite.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :show, id: other_suite.id
      expect(response.status).to be 404
    end
  end

  describe "GET #log", versioning: true do
    it "displays paper_trail versions related to the suite" do
      dummy   = create(:meeting)
      meeting = build(:meeting, suite: suite)
      meeting.save

      get :log, id: suite.id
      expect(response).to be_success

      expect(assigns(:versions).collect(&:id).uniq).to match_array((meeting.versions + suite.versions).collect(&:id))
    end
    it "gives a 404 if the instance does not match" do
      get :log, id: other_suite.id
      expect(response.status).to be 404
    end
  end

  describe "GET #new" do
    it "builds a suite" do
      get :new
      expect(response).to be_success
      expect(assigns(:suite).participants).to have(1).item
    end
  end
  describe "POST #new_from_template" do
    let(:template) { create(:suite, is_template: true) }
    it "builds an evaluation from a template" do
      post :new_from_template, suite: { template_id: template.id }
      expect(response).to be_success
      expect(assigns(:suite).template_id).to  be template.id
      expect(assigns(:suite).participants).to have(1).item
    end
    it "gives a 404 if the instance does not match" do
      template = create(:suite, is_template: true, instance: instance)
      post :new_from_template, suite: { template_id: template.id }
      expect(response.status).to be 404
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
      post(
        :create,
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
      )

      expect(response).to redirect_to(Suite.last)
      expect(Suite.last.participants.collect(&:student)).to match_array(students)
    end
    it "does not create participants when the suite is a template" do
      post(
        :create,
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
      )

      expect(response).to redirect_to(Suite.last)
      expect(Suite.last.participants).to be_empty
    end
    it "renders the new action if the suite is invalid" do
      post :create, suite: invalid_parameters_for(:suite)
      expect(response).to render_template("new")
    end
    it "sets the instance from the current user's active instance" do
      post :create, suite: valid_parameters_for(:suite).merge(instance_id: instance.id)
      expect(assigns(:suite).instance).not_to be instance
      expect(assigns(:suite).instance).to     eq logged_in_user.active_instance
    end
    it "accepts attributes for evaluations, meetings and participants" do
      # There is a bug that occurs if the has_many declarations in Suite are in
      # the wrong order. An after_create hook in Partipants caused incoming evaluations
      # to be wiped from the suite before they were saved. This was remedied by declaring
      # has_many :evaluations before has_many :participants in Suite.
      
      post(
        :create,
        suite: {
          name: "Test suite",
          is_template: "0",
          instance_id: logged_in_user.active_instance.id,
          participants_attributes: {
            "0" => {
              student_id: student_ids,
              group_id: group_ids
            }
          },
          evaluations_attributes: {
            "0" => {
              type: "suite",
              max_result: "8",
              colors_serialized: "{}",
              stanines_serialized: "{}",
              name: "Test evaluation",
              date: Date.today
            }
          },
          meetings_attributes: {
            "0" => {
              agenda: "<p>Test agenda</p>",
              name: "Test meeting",
              date: Date.today
            }
          }
        }
      )

      expect(response).to redirect_to(Suite.last)
      expect(Suite.last.participants.collect(&:student)).to match_array(students)

      expect(Suite.last.evaluations).to have(1).items
      expect(Suite.last.meetings).to have(1).items
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: suite.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :edit, id: other_suite.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #update" do
    it "redirects to the suite when successful" do
      new_name = "#{suite.name} updated" 
      put :update, id: suite.id, suite: { name: new_name }
      expect(response).to redirect_to(suite)
      expect(suite.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: suite.id, suite: invalid_parameters_for(:suite)
      expect(response).to render_template("edit")
    end
    it "gives a 404 if the instance does not match" do
      put :update, id: other_suite.id, suite: {}
      expect(response.status).to be 404
    end
    it "prevents changing the instance" do
      put :update, id: suite.id, suite: { instance_id: instance.id }
      expect(suite.reload.instance).not_to eq instance
    end
  end

  describe "GET #confirm_status_change" do
    it "switches the status without saving" do
      get :confirm_status_change, id: suite.id
      expect(response).to be_success
      expect(assigns(:suite).status.to_sym).to be :closed
      expect(assigns(:suite)).to be_changed
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_status_change, id: other_suite.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #change_status" do
    it "updates the status and redirects to the suite page" do
      put :change_status, id: suite.id, suite: { status: "closed" }
      expect(response).to redirect_to(suite)
      expect(suite.reload).to be_closed
    end
    it "renders the confirm_change_status view when validation fails" do
      put :change_status, id: suite.id, suite: { status: "invalid" }
      expect(response).to render_template("confirm_status_change")
    end
    it "gives a 404 if the instance does not match" do
      put :change_status, id: other_suite.id
      expect(response.status).to be 404
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: suite.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :confirm_destroy, id: other_suite.id
      expect(response.status).to be 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the suite list page" do
      delete :destroy, id: suite.id
      expect(response).to redirect_to(suites_url())
      expect(Suite.exists?(suite.id)).to be_false
    end
    it "redirects to the suite template list page when deleting templates" do
      suite.is_template = true
      suite.save!

      delete :destroy, id: suite.id
      expect(response).to redirect_to(template_suites_url())
      expect(Suite.exists?(suite.id)).to be_false
    end
    it "gives a 404 if the instance does not match" do
      delete :destroy, id: other_suite.id
      expect(response.status).to be 404
    end
  end

  describe "GET #select_users" do
    it "is successful" do
      get :select_users, id: suite.id
      expect(response).to be_success
    end
    it "gives a 404 if the instance does not match" do
      get :select_users, id: other_suite.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #add_users" do
    let(:users) { create_list(:user, 2) }

    it "gives the users suite_member privileges for the suite" do
      expect(users.first.has_role?(:suite_member, suite)).to be_false
      expect(users.second.has_role?(:suite_member, suite)).to be_false

      put :add_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
      expect(response).to redirect_to(suite)

      expect(users.first.has_role?(:suite_member, suite)).to be_true
      expect(users.second.has_role?(:suite_member, suite)).to be_true
    end
    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        put :add_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
        expect(updated_at).to be < suite.reload.updated_at
      end
    end
    it "gives a 404 if the instance does not match" do
      put :add_users, id: other_suite.id, suite: { user_id: users.collect(&:id).join(",") }
      expect(response.status).to be 404
    end
  end
  describe "DELETE #remove_users" do
    let(:users) { create_list(:user, 2) }

    it "removes the users' suite_member and suite_contributor privileges for the suite" do
      users.each { |u| u.add_role :suite_member, suite }
      users.first.add_role :suite_contributor, suite

      expect(users.first.has_role?(:suite_member, suite)).to be_true
      expect(users.first.has_role?(:suite_contributor, suite)).to be_true
      expect(users.second.has_role?(:suite_member, suite)).to be_true

      delete :remove_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
      expect(response).to redirect_to(suite)

      expect(users.first.has_role?(:suite_member, suite)).to be_false
      expect(users.first.has_role?(:suite_contributor, suite)).to be_false
      expect(users.second.has_role?(:suite_member, suite)).to be_false
    end
    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        delete :remove_users, id: suite.id, suite: { user_id: users.collect(&:id).join(",") }
        expect(updated_at).to be < suite.reload.updated_at
      end
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_users, id: other_suite.id, suite: { user_id: users.collect(&:id).join(",") }
      expect(response.status).to be 404
    end
  end

  describe "PUT #add_contributors" do
    let(:users) { create_list(:user, 2) }

    it "gives the users suite_contributor privileges for the suite" do
      expect(users.first.has_role?(:suite_contributor, suite)).to be_false
      expect(users.second.has_role?(:suite_contributor, suite)).to be_false

      put :add_contributors, id: suite.id, user_ids: users.collect(&:id)
      expect(response).to be_success

      expect(users.first.has_role?(:suite_contributor, suite)).to be_true
      expect(users.second.has_role?(:suite_contributor, suite)).to be_true
    end
    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        put :add_contributors, id: suite.id, user_ids: users.collect(&:id)
        expect(updated_at).to be < suite.reload.updated_at
      end
    end
    it "gives a 404 if the instance does not match" do
      put :add_contributors, id: other_suite.id, user_ids: users.collect(&:id)
      expect(response.status).to be 404
    end
  end
  describe "PUT #remove_contributors" do
    let(:users) { create_list(:user, 2) }

    it "removes the users suite_contributor privileges for the suite" do
      users.each { |u| u.add_role :suite_contributor, suite }

      expect(users.first.has_role?(:suite_contributor, suite)).to be_true
      expect(users.second.has_role?(:suite_contributor, suite)).to be_true

      delete :remove_contributors, id: suite.id, user_ids: users.collect(&:id)
      expect(response).to be_success

      expect(users.first.has_role?(:suite_contributor, suite)).to be_false
      expect(users.second.has_role?(:suite_contributor, suite)).to be_false
    end
    it "touches the suite" do
      updated_at = suite.updated_at
      Timecop.freeze(Time.now + 5.minutes) do
        delete :remove_contributors, id: suite.id, user_ids: users.collect(&:id)
        expect(updated_at).to be < suite.reload.updated_at
      end
    end
    it "gives a 404 if the instance does not match" do
      delete :remove_contributors, id: other_suite.id, user_ids: users.collect(&:id).join(",")
      expect(response.status).to be 404
    end
  end
end
