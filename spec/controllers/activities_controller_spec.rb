require 'spec_helper'

describe ActivitiesController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:activity) { create(:activity) }

  describe "GET #show" do
    it "is successful" do
      get :show, id: activity.id
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: activity.id
      expect(response).to be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the activity when successful" do
      new_name = "#{activity.name} updated"
      put :update, id: activity.id, activity: { name: new_name }
      expect(response).to redirect_to(activity)
      expect(activity.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: activity.id, activity: invalid_parameters_for(:activity)
      expect(response).to render_template("edit")
    end
  end

  describe "GET #report" do
    it "sets the activity to closed" do
      get :report, id: activity.id
      expect(response).to be_success
      expect(assigns(:activity).status.to_sym).to eq :closed
    end
  end
  describe "PUT #submit_report" do
    it "redirects to the activity when successful" do
      new_name = "#{activity.name} updated" 
      put :submit_report, id: activity.id, activity: { name: new_name }
      expect(response).to redirect_to(activity)
      expect(activity.reload.name).to eq new_name
    end
    it "renders the edit view when validation fails" do
      put :submit_report, id: activity.id, activity: invalid_parameters_for(:activity)
      expect(response).to render_template("report")
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: activity.id
      expect(response).to be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the activity's suite" do
      delete :destroy, id: activity.id
      expect(response).to redirect_to(activity.suite)
      expect(Activity.exists?(activity.id)).to be_false
    end
  end
end
