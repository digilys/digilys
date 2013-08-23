require 'spec_helper'

describe IndexController do
  describe "GET #index" do
    let(:user)       { create(:user) }
    let(:other_user) { create(:user) }

    let!(:suite)              { create(:suite) }
    let!(:inaccessible_suite) { create(:suite) }

    let!(:overdue_evaluation)                { create(:suite_evaluation, suite: suite, date: Date.today - 2.days) }
    let!(:upcoming_evaluation)               { create(:suite_evaluation, suite: suite, date: Date.today + 1.day) }
    let!(:overdue_evaluation_for_user)       { create(:suite_evaluation, suite: suite, date: Date.today - 2.days) }
    let!(:overdue_evaluation_for_other_user) { create(:suite_evaluation, suite: suite, date: Date.today - 2.days) }
    let!(:inaccessible_overdue_evaluations)  { create(:suite_evaluation,               date: Date.today - 2.days) }
    let!(:inaccessible_upcoming_evaluations) { create(:suite_evaluation,               date: Date.today - 2.days) }

    let!(:upcoming_meeting)              { create(:meeting, suite: suite, date: Date.today + 1.day) }
    let!(:overdue_meeting)               { create(:meeting, suite: suite, date: Date.today - 1.day) }
    let!(:inaccessible_upcoming_meeting) { create(:meeting,               date: Date.today + 1.day) }
    let!(:inaccessible_overdue_meeting)  { create(:meeting,               date: Date.today - 1.day) }

    let!(:open_activity)   { create(:activity, users: [user], status: :open) }
    let!(:closed_activity) { create(:activity, users: [user], status: :closed) }

    before(:each) do
      user.grant       :suite_contributor, suite
      other_user.grant :suite_contributor, suite

      overdue_evaluation_for_user.users       << user
      overdue_evaluation_for_other_user.users << other_user

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
      assigns(:evaluations)[:overdue].should  == [overdue_evaluation, overdue_evaluation_for_user]
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
