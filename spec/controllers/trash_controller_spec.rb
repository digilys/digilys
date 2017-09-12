require 'spec_helper'

describe TrashController do

  describe "GET #index for admin" do
    login_user(:admin)
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET #index for instance admin" do
    login_user(:user)
    before(:each) do
      logged_in_user.add_role(:instance_admin, logged_in_user.active_instance)
      logged_in_user.save
    end
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET #index for planner" do
    login_user(:user)
    before(:each) do
      logged_in_user.add_role(:planner)
      logged_in_user.save
    end
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET #index for regular user (member)" do
  login_user(:user)
    it "returns 401" do
      get :index
      expect(response.status).to be 401
    end
  end
end
