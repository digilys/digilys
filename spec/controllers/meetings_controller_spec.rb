require 'spec_helper'

describe MeetingsController do
  login_user(:admin)

  let(:meeting) { create(:meeting) }

  describe "GET #show" do
    it "is successful" do
      get :show, id: meeting.id
      response.should be_success
    end
  end

  describe "GET #new" do
    it "is successful" do
      get :new, suite_id: meeting.suite_id
      response.should be_success
    end
  end
  describe "POST #create" do
    it "redirects to the meeting when successful" do
      post :create, suite_id: meeting.suite_id, meeting: valid_parameters_for(:meeting)
      response.should redirect_to(assigns(:meeting))
    end
    it "renders the new view when validation fails" do
      post :create, meeting: invalid_parameters_for(:meeting)
      response.should render_template("new")
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: meeting.id
      response.should be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the meeting when successful" do
      new_name = "#{meeting.name} updated" 
      put :update, id: meeting.id, meeting: { name: new_name }
      response.should redirect_to(meeting)
      meeting.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :update, id: meeting.id, meeting: invalid_parameters_for(:meeting)
      response.should render_template("edit")
    end
  end

  describe "GET #report" do
    it "prepares a meeting for completion" do
      meeting.activities.should be_blank

      get :report, id: meeting.id
      response.should be_success

      assigns(:meeting).activities.should have(1).item
      assigns(:meeting).completed.should be_true
    end
  end
  describe "PUT #submit_report" do
    it "redirects to the meeting when successful" do
      new_name = "#{meeting.name} updated" 
      put :submit_report, id: meeting.id, meeting: { name: new_name }
      response.should redirect_to(meeting)
      meeting.reload.name.should == new_name
    end
    it "renders the edit view when validation fails" do
      put :submit_report, id: meeting.id, meeting: invalid_parameters_for(:meeting)
      response.should render_template("report")
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get :confirm_destroy, id: meeting.id
      response.should be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the meeting list page" do
      delete :destroy, id: meeting.id
      response.should redirect_to(meeting.suite)
      Meeting.exists?(meeting.id).should be_false
    end
  end
end
