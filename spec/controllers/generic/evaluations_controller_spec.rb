require 'spec_helper'

describe Generic::EvaluationsController do
  login_user(:admin)

  let(:instance) { create(:instance) }

  describe "GET #index" do
    let!(:generics)       { create_list(:generic_evaluation,  2) }
    let!(:others)         { create_list(:evaluation_template, 2) }
    let!(:other_instance) { create(     :generic_evaluation,  instance: instance)}

    it "gives a list of generic evaluations" do
      get :index
      response.should be_success
      assigns(:evaluations).should match_array(generics)
    end
    it "is filterable" do
      get :index, q: { name_cont: generics.first.name }
      response.should be_success
      assigns(:evaluations).should == [generics.first]
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
