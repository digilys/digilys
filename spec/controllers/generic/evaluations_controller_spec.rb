require 'spec_helper'

describe Generic::EvaluationsController do
  login_admin

  describe "GET #index" do
    let!(:generics) { create_list(:generic_evaluation,  2) }
    let!(:others)   { create_list(:evaluation_template, 2) }

    it "gives a list of generic evaluations" do
      get :index
      response.should be_success
      assigns(:evaluations).should match_array(generics)
    end
  end

  describe "GET #new" do
    it "builds a generic evaluation" do
      get :new
      response.should be_success
      assigns(:evaluation).type.to_sym.should == :generic
    end
  end
end
