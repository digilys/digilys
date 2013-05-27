require 'spec_helper'

describe EvaluationsController do
  login_admin

  describe "GET #report" do
    let!(:suite)        { create(:suite) }
    let!(:evaluation)   { create(:suite_evaluation, suite: suite) }
    let!(:participants) { create_list(:participant, 2, suite: suite)}

    it "generates unsaved results for participants" do
      get :report, id: evaluation.id
      assigns(:evaluation).results.collect(&:student).should match_array(participants.collect(&:student))
      assigns(:evaluation).results.collect(&:new_record?).should == [ true, true ]
    end
    it "does not generate results if they already exist" do
      results = [
        create(:result, student: participants.first.student,  evaluation: evaluation),
        create(:result, student: participants.second.student, evaluation: evaluation)
      ]

      get :report, id: evaluation.id
      assigns(:evaluation).results.should match_array(results)
    end
  end
end
