require 'spec_helper'

describe EvaluationsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:evaluation)               { create(:suite_evaluation) }
  let(:generic_evaluation)       { create(:generic_evaluation) }
  let(:instance)                 { create(:instance) }
  let(:other_suite)              { create(:suite,              instance: instance) }
  let(:other_evaluation)         { create(:suite_evaluation,   suite:    other_suite) }
  let(:other_generic_evaluation) { create(:generic_evaluation, instance: instance) }

  describe "#instance_filter" do
    it "disallows evaluation templates" do
      get :show, id: create(:evaluation_template, instance: instance).id
      expect(response.status).to be 404
    end
  end

  describe "GET #search" do
    let(:suite)                     { create(:suite, name: "foo")}
    let(:suite_template)            { create(:suite, name: "foo", is_template: true)}

    let(:generic)                   { create(:generic_evaluation, name: "bar 1") }
    let(:suite_evaluation)          { create(:suite_evaluation, name: "bar 2") }
    let(:suite_template_evaluation) { create(:suite_evaluation, name: "bar 2", suite: suite_template) }
    let(:template)                  { create(:evaluation_template) }

    let!(:evaluations)              { [ generic, suite_evaluation, suite_template_evaluation ] }
    let!(:non_instance)             { other_evaluation }

    it "lists generic and non-template suite evaluations from the correct instance" do
      get :search, q: {}
      expect(response).to be_success
      expect(assigns(:evaluations)).to match_array([generic, suite_evaluation])
    end
    it "returns the result as json" do
      get :search, q: { name_cont: generic.name }

      json = JSON.parse(response.body)

      expect(json["more"]).to be_false

      expect(json["results"]).to have(1).items
      expect(json["results"].first).to include("id"   => generic.id)
      expect(json["results"].first).to include("text" => generic.name)
    end
    it "supports searching for suite names" do
      get :search, q: { suite_name_cont: suite_evaluation.suite.name }
      expect(assigns(:evaluations)).to match_array([suite_evaluation])
    end

    it "considers comma signs multiple terms" do
      get :search, q: { name_cont_any: "bar 1,bar 2" }
      expect(assigns(:evaluations)).to match_array([generic, suite_evaluation])
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: evaluation.id
      expect(response).to be_success
    end
    it "generates a 404 if the suite instance does not match" do
      get :show, id: other_evaluation.id
      expect(response.status).to be 404
    end
    it "generates a 404 if the instance does not match" do
      get :show, id: other_generic_evaluation.id
      expect(response.status).to be 404
    end
  end

  describe "GET #new" do
    it "builds a suite evaluation" do
      get :new, suite_id: evaluation.suite_id
      expect(response).to be_success

      expect(assigns(:evaluation).type.to_sym).to eq :suite
      expect(assigns(:suite)).to                  eq evaluation.suite
    end
    it "generates a 404 if the suite instance does not match" do
      get :new, suite_id: other_suite.id
      expect(response.status).to be 404
    end
  end
  describe "POST #new_from_template" do
    let(:template)  { create(:evaluation_template) }
    let(:template2) { create(:evaluation_template) }
    let(:template3) { create(:evaluation_template) }
    let(:suite)     { create(:suite) }
    let(:suite_template)     { create(:suite, is_template: true) }
    it "builds an evaluation from a template" do
      post :new_from_template, evaluation: { template_id: template.id, suite_id: suite.id }
      expect(response).to be_success
      expect(assigns(:evaluation).template_id).to eq template.id
      expect(assigns(:evaluation).suite_id).to    eq suite.id
    end
    it "adds all templates to suite if several" do
      ids = [template.id, template2.id, template3.id]
      post :new_from_template, evaluation: { template_id: ids.join(","), suite_id: suite_template.id, type: "suite" }
      expect(response).to redirect_to(suite_template)
      expect(suite_template.evaluations.count).to eq 3
    end
    it "does not add templates to suite if suite is not template" do
      ids = [template.id, template2.id, template3.id]
      post :new_from_template, evaluation: { template_id: ids.join(","), suite_id: suite.id, type: "suite" }
      expect(response).to render_template("new")
      expect(suite.evaluations.count).to eq 0
    end
    it "generates a 404 if the suite instance does not match" do
      post :new_from_template, evaluation: { template_id: template.id, suite_id: other_suite.id }
      expect(response.status).to be 404
    end
    it "builds an evaluation from a template without suite" do
      post :new_from_template, evaluation: { template_id: template.id, suite_id: "" }
      expect(response).to be_success
      expect(assigns(:evaluation).template_id).to eq template.id
      expect(assigns(:evaluation).suite_id).to    eq nil
    end
  end
  describe "POST #create" do
    it "redirects to the newly created evaluation on success" do
      post :create, evaluation: valid_parameters_for(:evaluation)
      expect(response).to redirect_to(assigns(:evaluation))
    end
    it "renders the new action on invalid parameters" do
      post :create, evaluation: invalid_parameters_for(:evaluation)
      expect(response).to render_template("new")
    end
    it "generates a 404 if the suite instance does not match" do
      post :create, evaluation: valid_parameters_for(:evaluation).merge(type: :suite, suite_id: other_suite.id)
      expect(response.status).to be 404
    end
    it "sets the instance from the current user's active instance" do
      post :create, evaluation: valid_parameters_for(:evaluation)
      expect(assigns(:evaluation).instance).to eq logged_in_user.active_instance
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: evaluation.id
      expect(response).to be_success
    end
    it "generates a 404 if the suite instance does not match" do
      get :edit, id: other_evaluation.id
      expect(response.status).to be 404
    end
    it "generates a 404 if the instance does not match" do
      get :edit, id: other_generic_evaluation.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #update" do
    let(:user_1) { create(:user) }
    let(:user_2) { create(:user) }

    it "redirects to the evaluation when successful" do
      new_name = "#{evaluation.name} updated"
      put :update, id: evaluation.id, evaluation: { name: new_name }
      expect(response).to redirect_to(evaluation)
      expect(evaluation.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: evaluation.id, evaluation: invalid_parameters_for(:evaluation)
      expect(response).to render_template("edit")
    end
    it "generates a 404 if the suite instance does not match" do
      put :update, id: other_evaluation.id, evaluation: {}
      expect(response.status).to be 404
    end
    it "generates a 404 if the instance does not match" do
      put :update, id: other_generic_evaluation.id, evaluation: {}
      expect(response.status).to be 404
    end
    it "prevents changing the instance" do
      put :update, id: generic_evaluation.id, evaluation: { instance_id: instance.id }
      expect(generic_evaluation.reload.instance).not_to eq instance
    end
    it "adds users to the evaluation" do
      put :update, id: evaluation.id, evaluation: { user_ids: [user_1.id, user_2.id].join(",") }
      expect(response).to redirect_to(evaluation)
      expect(evaluation.users.length).to eq 2
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: evaluation.id
      expect(response).to be_success
    end
    it "generates a 404 if the suite instance does not match" do
      get :confirm_destroy, id: other_evaluation.id
      expect(response.status).to be 404
    end
    it "generates a 404 if the instance does not match" do
      get :confirm_destroy, id: other_generic_evaluation.id
      expect(response.status).to be 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the evaluation's suite for suite evaluations" do
      delete :destroy, id: evaluation.id
      expect(response).to redirect_to(evaluation.suite)
      expect(Evaluation.exists?(evaluation.id)).to be_false
    end
    it "redirects to the template evaluations controller for template evaluations" do
      delete :destroy, id: create(:evaluation_template).id
      expect(response).to redirect_to(template_evaluations_url())
    end
    it "redirects to the generic evaluations controller for generic evaluations" do
      delete :destroy, id: create(:generic_evaluation).id
      expect(response).to redirect_to(generic_evaluations_url())
    end
    it "generates a 404 if the suite instance does not match" do
      delete :destroy, id: other_evaluation.id
      expect(response.status).to be 404
    end
    it "generates a 404 if the instance does not match" do
      delete :destroy, id: other_generic_evaluation.id
      expect(response.status).to be 404
    end
    it "marks as deleted" do
      expect {
        delete :destroy, id: evaluation.id
      }.to change { Evaluation.deleted.size }.from(0).to(1)
    end
  end

  describe "GET #report" do
    let(:male_participants)   { create_list(:male_participant,   1, suite: evaluation.suite) }
    let(:female_participants) { create_list(:female_participant, 1, suite: evaluation.suite) }
    let!(:participants)       { male_participants + female_participants }

    it "generates unsaved results for participants" do
      get :report, id: evaluation.id
      expect(assigns(:evaluation).results.collect(&:student)).to match_array(participants.collect(&:student))
      expect(assigns(:evaluation).results.collect(&:new_record?)).to eq [ true ] * participants.length
    end
    it "does not generate results if they already exist" do
      results = participants.collect { |p| create(:result, student: p.student, evaluation: evaluation) }

      get :report, id: evaluation.id
      expect(assigns(:evaluation).results).to match_array(results)
    end
    it "limits the participants depending on the target of the evaluation" do
      evaluation.target = :female
      evaluation.save!

      get :report, id: evaluation.id
      expect(assigns(:evaluation).results.collect(&:student)).to match_array(female_participants.collect(&:student))
    end
    it "generates a 404 if the suite instance does not match" do
      get :report, id: other_evaluation.id
      expect(response.status).to be 404
    end
  end
  describe "POST #report_all" do
    let(:suite)       { create(:suite) }
    let(:evaluations) { [
      create(:suite_evaluation, suite: suite),
      create(:suite_evaluation, suite: suite, target: :female)
    ] }
    let(:participants) { [
      create(:male_participant,   suite: suite),
      create(:female_participant, suite: suite)
    ] }

    it "is successful" do
      post :report_all, suite_id: suite.id, ids: evaluations.collect(&:id)
      expect(response).to be_successful
      expect(assigns(:evaluations)).to match_array(evaluations)
    end
    it "builds results where missing for an evaluation's participants" do
      # One existing result
      create(:result, evaluation: evaluations.first, student: participants.second.student)

      post :report_all, suite_id: suite.id, ids: evaluations.collect(&:id)

      # It builds two results, one for the female in the female evaluation
      # one for the male in the other evaluation
      assigns(:evaluations).each do |evaluation|
        if evaluation.target.female?
          expect(evaluation.results).to have(1).items
          expect(evaluation.results.first.new_record?).to be_true
          expect(evaluation.results.first.student_id).to  eq participants.second.student_id
        else
          expect(evaluation.results).to have(2).items

          evaluation.results.each do |r|
            if r.new_record?
              expect(r.student_id).to eq participants.first.student_id
            else
              expect(r.student_id).to eq participants.second.student_id
            end
          end
        end
      end
    end
    it "redirects to the suite if there are no evaluation ids" do
      post :report_all, suite_id: suite.id, ids: []
      expect(response).to redirect_to(suite)
    end
    it "redirects to the regular report interface if there is only one evaluation id" do
      post :report_all, suite_id: suite.id, ids: [evaluation.id]
      expect(response).to redirect_to(report_evaluation_url(evaluation))
    end
    it "generates a 404 if the suite instance does not match" do
      post :report_all, suite_id: other_suite.id, ids: [other_evaluation.id]
      expect(response.status).to be 404
    end
  end
  describe "POST #submit_report_all" do
    let(:suite)       { create(:suite) }
    let(:evaluations) { create_list(:suite_evaluation, 2, suite: suite) }
    let(:students)    { create_list(:student, 2) }

    it "redirects to the suite" do
      post :submit_report_all, suite_id: suite.id, results: []
      expect(response).to redirect_to(suite)
    end
    it "creates new results with values or absent flags where missing, skipping blank results" do
      req = {
        evaluations.first.id.to_s => {
          students.first.id.to_s => "1",
          students.second.id.to_s => "absent"
        },
        evaluations.second.id.to_s => {
          students.second.id.to_s => "2"
        }
      }
      post :submit_report_all, suite_id: suite.id, results: req

      results = evaluations.first.results(true)
      expect(results).to have(2).items
      result = results.detect { |r| r.student_id == students.first.id }
      expect(result.value).to eq 1
      result = results.detect { |r| r.student_id == students.second.id }
      expect(result.absent).to be_true

      results = evaluations.second.results(true)
      expect(results).to have(1).items
      expect(results.first.value).to eq 2
      expect(results.first.student_id).to eq students.second.id
    end
    it "updates existing results" do
      res1 = create(:result, value: 1,   evaluation: evaluations.first,  student: students.second)
      res2 = create(:result, value: nil, evaluation: evaluations.second, student: students.second, absent: true)

      req = {
        evaluations.first.id.to_s => {
          students.first.id.to_s => "1",
          students.second.id.to_s => "absent"
        },
        evaluations.second.id.to_s => {
          students.second.id.to_s => "2"
        }
      }
      post :submit_report_all, suite_id: suite.id, results: req

      results = evaluations.first.results(true)
      expect(results).to have(2).items
      result = results.detect { |r| r.student_id == students.first.id }
      expect(result.value).to eq 1
      result = results.detect { |r| r.student_id == students.second.id }
      expect(result.absent).to be_true
      expect(result.id).to eq res1.id

      results = evaluations.second.results(true)
      expect(results).to have(1).items
      expect(results.first.value).to eq 2
      expect(results.first.student_id).to eq students.second.id
      expect(results.first.id).to eq res2.id
    end
    it "destroys results when receiving blank values for existing results" do
      res1 = create(:result, value: 1,   evaluation: evaluations.first,  student: students.second)
      res2 = create(:result, value: nil, evaluation: evaluations.second, student: students.second, absent: true)

      req = {
        evaluations.first.id.to_s => {
          students.second.id.to_s => ""
        },
        evaluations.second.id.to_s => {
          students.second.id.to_s => ""
        }
      }
      post :submit_report_all, suite_id: suite.id, results: req

      expect(Result.exists?(res1.id)).to be_false
      expect(Result.exists?(res2.id)).to be_false
    end
    it "generates a 404 if the suite instance does not match" do
      post :submit_report_all, suite_id: other_suite.id, results: []
      expect(response.status).to be 404
    end
  end
  describe "DELETE #destroy_report" do
    it "redirects to the evaluation's report action when successful" do
      delete :destroy_report, id: evaluation.id
      expect(response).to redirect_to(report_evaluation_url(evaluation))
    end
    it "generates a 404 if the suite instance does not match" do
      delete :destroy_report, id: other_evaluation.id
      expect(response.status).to be 404
    end
  end
  describe "PUT #restore" do
    let!(:deleted_evaluation)       { create(:suite_evaluation, deleted_at: "2015-01-01 00:00") }
    it "redirects to trash" do
      put :restore, id: deleted_evaluation.id
      expect(response).to redirect_to(trash_index_path)
    end
    it "restores evaluation" do
      put :restore, id: deleted_evaluation.id
      expect(deleted_evaluation.reload.deleted_at?).to be_false
    end
  end
  describe "PUT #restore ordinary user" do
    let!(:deleted_evaluation)       { create(:suite_evaluation, deleted_at: "2015-01-01 00:00") }
    login_user(:user)
    it "returns 401 if user is not admin" do
      put :restore, id: deleted_evaluation.id
      expect(response.status).to be 401
    end
  end
end
