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
      expect(response.status).to be 401
    end
  end

  describe "GET #index for regular user (member)" do
  login_user(:user)
    it "returns 401" do
      get :index
      expect(response.status).to be 401
    end
  end

  describe "GET #confirmed_empty for admin" do
    login_user(:admin)
    let!(:suite_1) { create(:suite) }
    let!(:suite_2) { create(:suite) }
    let!(:evaluation_1) { create(:evaluation) }
    let!(:evaluation_2) { create(:evaluation) }
    before(:each) do
      suite_1.destroy
      suite_2.destroy
      evaluation_1.destroy
      evaluation_2.destroy
    end
    it "empties trash" do
      expect(Suite.count).to eq 0
      expect(Suite.deleted.count).to eq 2
      expect(Evaluation.count).to eq 0
      expect(Evaluation.deleted.count).to eq 2
      get :confirmed_empty
      expect(Suite.count).to eq 0
      expect(Suite.deleted.count).to eq 0
      expect(Evaluation.count).to eq 0
      expect(Evaluation.deleted.count).to eq 0
    end
  end
end
