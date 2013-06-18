require 'spec_helper'

describe IndexController do
  describe "GET #index" do
    let(:user) { create(:user) }

    let!(:suite)              { create(:suite) }
    let!(:inaccessible_suite) { create(:suite) }

    let!(:overdue_evaluation)       { create(:suite_evaluation, suite: suite, date: Date.today - 2.days) }
    let!(:upcoming_evaluation)      { create(:suite_evaluation, suite: suite, date: Date.today + 1.day) }
    let!(:inaccessible_evaluations) { create(:suite_evaluation) }

    let!(:upcoming_meeting)     { create(:meeting, suite: suite, date: Date.today + 1.day) }
    let!(:overdue_meeting)      { create(:meeting, suite: suite, date: Date.today - 1.day) }
    let!(:inaccessible_meeting) { create(:meeting) }

    let!(:open_activity)   { create(:activity, users: [user], status: :open) }
    let!(:closed_activity) { create(:activity, users: [user], status: :closed) }

    before(:each) do
      user.grant :suite_contributor, suite

      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
    end

    it "is successful" do
      get :index
      response.should be_success
    end
    it "lists accessible suites" do
      get :index
      assigns(:suites).should == [suite]
    end
    it "lists upcoming and overdue accessible evaluations" do
      get :index
      assigns(:evaluations)[:overdue].should  == [overdue_evaluation]
      assigns(:evaluations)[:upcoming].should == [upcoming_evaluation]
    end
    it "lists upcoming accessible meetings" do
      get :index
      assigns(:meetings).should == [upcoming_meeting]
    end
    it "lists the user's open activities" do
      get :index
      assigns(:activities).should == [open_activity]
    end
  end
end
