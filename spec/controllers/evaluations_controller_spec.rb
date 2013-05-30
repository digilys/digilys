require 'spec_helper'

describe EvaluationsController do
  login_admin

  describe "GET #report" do
    let!(:suite)               { create(:suite) }

    let!(:male_participants)   { create_list(:male_participant,   3, suite: suite) }
    let!(:female_participants) { create_list(:female_participant, 3, suite: suite) }

    let!(:evaluation)          { create(:suite_evaluation, suite: suite) }
    let!(:participants)        { male_participants + female_participants }

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
  end
end
