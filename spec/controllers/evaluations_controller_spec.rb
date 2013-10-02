require 'spec_helper'

describe EvaluationsController do
  login_user(:admin)

  let(:evaluation)               { create(:suite_evaluation) }
  let(:generic_evaluation)       { create(:generic_evaluation) }
  let(:instance)                 { create(:instance) }
  let(:other_suite)              { create(:suite,              instance: instance) }
  let(:other_evaluation)         { create(:suite_evaluation,   suite:    other_suite) }
  let(:other_generic_evaluation) { create(:generic_evaluation, instance: instance) }

  describe "#instance_filter" do
    it "allows all evaluation templates" do
      get :show, id: create(:evaluation_template).id
      response.should be_success
    end
  end

  describe "GET #show" do
    it "is successful" do
      get :show, id: evaluation.id
      response.should be_success
    end
    it "generates a 404 if the suite instance does not match" do
      get :show, id: other_evaluation.id
    end
    it "generates a 404 if the instance does not match" do
      get :show, id: other_generic_evaluation.id
    end
  end

  describe "GET #new" do
    it "builds a suite evaluation" do
      get :new, suite_id: evaluation.suite_id
      response.should be_success

      assigns(:evaluation).type.to_sym.should == :suite
      assigns(:suite).should                  == evaluation.suite
    end
    it "generates a 404 if the suite instance does not match" do
      get :new, suite_id: other_suite.id
      response.status.should == 404
    end
  end
  describe "POST #new_from_template" do
    let(:template) { create(:evaluation_template) }
    let(:suite)    { create(:suite) }
    it "builds an evaluation from a template" do
      post :new_from_template, evaluation: { template_id: template.id, suite_id: suite.id }
      response.should be_success
      assigns(:evaluation).template_id.should == template.id
      assigns(:evaluation).suite_id.should    == suite.id
    end
    it "generates a 404 if the suite instance does not match" do
      post :new_from_template, evaluation: { template_id: template.id, suite_id: other_suite.id }
      response.status.should == 404
    end
  end
  describe "POST #create" do
    it "redirects to the newly created evaluation on success" do
      post :create, evaluation: valid_parameters_for(:evaluation)
      response.should redirect_to(assigns(:evaluation))
    end
    it "renders the new action on invalid parameters" do
      post :create, evaluation: invalid_parameters_for(:evaluation)
      response.should render_template("new")
    end
    it "generates a 404 if the suite instance does not match" do
      post :create, evaluation: valid_parameters_for(:evaluation).merge(type: :suite, suite_id: other_suite.id)
      response.status.should == 404
    end
    it "generates a 404 if the instance does not match" do
      post :create, evaluation: valid_parameters_for(:evaluation).merge(type: :generic, instance_id: instance.id)
      response.status.should == 404
    end
    it "sets the instance from the current user's active instance" do
      post :create, evaluation: valid_parameters_for(:evaluation)
      assigns(:evaluation).instance.should == logged_in_user.active_instance
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: evaluation.id
      response.should be_success
    end
    it "generates a 404 if the suite instance does not match" do
      get :edit, id: other_evaluation.id
      response.status.should == 404
    end
    it "generates a 404 if the instance does not match" do
      get :edit, id: other_generic_evaluation.id
      response.status.should == 404
    end
  end
  describe "PUT #update" do
    it "redirects to the evaluation when successful" do
      new_name = "#{evaluation.name} updated" 
      put :update, id: evaluation.id, evaluation: { name: new_name }
      response.should redirect_to(evaluation)
      evaluation.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: evaluation.id, evaluation: invalid_parameters_for(:evaluation)
      response.should render_template("edit")
    end
    it "generates a 404 if the suite instance does not match" do
      put :update, id: other_evaluation.id, evaluation: {}
      response.status.should == 404
    end
    it "generates a 404 if the instance does not match" do
      put :update, id: other_generic_evaluation.id, evaluation: {}
      response.status.should == 404
    end
    it "prevents changing the instance" do
      put :update, id: generic_evaluation.id, evaluation: { instance_id: instance.id }
      generic_evaluation.reload.instance.should_not == instance
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: evaluation.id
      response.should be_success
    end
    it "generates a 404 if the suite instance does not match" do
      get :confirm_destroy, id: other_evaluation.id
      response.status.should == 404
    end
    it "generates a 404 if the instance does not match" do
      get :confirm_destroy, id: other_generic_evaluation.id
      response.status.should == 404
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the evaluation's suite for suite evaluations" do
      delete :destroy, id: evaluation.id
      response.should redirect_to(evaluation.suite)
      Evaluation.exists?(evaluation.id).should be_false
    end
    it "redirects to the template evaluations controller for template evaluations" do
      delete :destroy, id: create(:evaluation_template).id
      response.should redirect_to(template_evaluations_url())
    end
    it "redirects to the generic evaluations controller for generic evaluations" do
      delete :destroy, id: create(:generic_evaluation).id
      response.should redirect_to(generic_evaluations_url())
    end
    it "generates a 404 if the suite instance does not match" do
      delete :destroy, id: other_evaluation.id
      response.status.should == 404
    end
    it "generates a 404 if the instance does not match" do
      delete :destroy, id: other_generic_evaluation.id
      response.status.should == 404
    end
  end

  describe "GET #report" do
    let(:male_participants)   { create_list(:male_participant,   3, suite: evaluation.suite) }
    let(:female_participants) { create_list(:female_participant, 3, suite: evaluation.suite) }
    let!(:participants)       { male_participants + female_participants }

    it "generates unsaved results for participants" do
      get :report, id: evaluation.id
      assigns(:evaluation).results.collect(&:student).should match_array(participants.collect(&:student))
      assigns(:evaluation).results.collect(&:new_record?).should == [ true ] * participants.length
    end
    it "does not generate results if they already exist" do
      results = participants.collect { |p| create(:result, student: p.student, evaluation: evaluation) }

      get :report, id: evaluation.id
      assigns(:evaluation).results.should match_array(results)
    end
    it "limits the participants depending on the target of the evaluation" do
      evaluation.target = :female
      evaluation.save!

      get :report, id: evaluation.id
      assigns(:evaluation).results.collect(&:student).should match_array(female_participants.collect(&:student))
    end
    it "generates a 404 if the suite instance does not match" do
      get :report, id: other_evaluation.id
      response.status.should == 404
    end
  end
  describe "PUT #submit_report" do
    it "redirects to the evaluation's suite when successful" do
      new_name = "#{evaluation.name} updated" 
      put :submit_report, id: evaluation.id, evaluation: { name: new_name }
      response.should redirect_to(evaluation.suite)
      evaluation.reload.name.should == new_name
    end
    it "renders the report view when validation fails" do
      put :submit_report, id: evaluation.id, evaluation: invalid_parameters_for(:evaluation)
      response.should render_template("report")
    end
    it "generates a 404 if the suite instance does not match" do
      put :submit_report, id: other_evaluation.id, evaluation: {}
      response.status.should == 404
    end
  end
  describe "DELETE #destroy_report" do
    it "redirects to the evaluation's report action when successful" do
      delete :destroy_report, id: evaluation.id
      response.should redirect_to(report_evaluation_url(evaluation))
    end
    it "generates a 404 if the suite instance does not match" do
      delete :destroy_report, id: other_evaluation.id
      response.status.should == 404
    end
  end
end
