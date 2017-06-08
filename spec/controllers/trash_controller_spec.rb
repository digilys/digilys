require 'spec_helper'

describe TrashController do

  login_user(:admin)

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET #index for non admin" do
  login_user(:user)
    it "returns 401" do
      get :index
      expect(response.status).to be 401
    end
  end
end
