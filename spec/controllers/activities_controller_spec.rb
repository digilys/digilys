require 'spec_helper'

describe ActivitiesController do
  login_user(:admin)

  let(:activity) { create(:activity) }

  describe "GET #show" do
    it "is successful" do
      get :show, id: activity.id
      response.should be_success
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: activity.id
      response.should be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the activity when successful" do
      new_name = "#{activity.name} updated"
      put :update, id: activity.id, activity: { name: new_name }
      response.should redirect_to(activity)
      activity.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: activity.id, activity: invalid_parameters_for(:activity)
      response.should render_template("edit")
    end
  end

  describe "GET #report" do
    it "sets the activity to closed" do
      get :report, id: activity.id
      response.should be_success
      assigns(:activity).status.to_sym.should == :closed
    end
  end
  describe "PUT #submit_report" do
    it "redirects to the activity when successful" do
      new_name = "#{activity.name} updated" 
      put :submit_report, id: activity.id, activity: { name: new_name }
      response.should redirect_to(activity)
      activity.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :submit_report, id: activity.id, activity: invalid_parameters_for(:activity)
      response.should render_template("report")
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: activity.id
      response.should be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the activity's suite" do
      delete :destroy, id: activity.id
      response.should redirect_to(activity.suite)
      Activity.exists?(activity.id).should be_false
    end
  end
end
