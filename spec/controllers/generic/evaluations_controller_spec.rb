require 'spec_helper'

describe Generic::EvaluationsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance) { create(:instance) }

  describe "GET #index" do
    let!(:generics)       { create_list(:generic_evaluation,  2) }
    let!(:others)         { create_list(:evaluation_template, 2) }
    let!(:other_instance) { create(     :generic_evaluation,  instance: instance)}

    it "gives a list of generic evaluations" do
      get :index
      expect(response).to be_success
      expect(assigns(:evaluations)).to match_array(generics)
    end
    it "is filterable" do
      get :index, q: { name_cont: generics.first.name }
      expect(response).to be_success
      expect(assigns(:evaluations)).to eq [generics.first]
    end
  end

  describe "GET #new" do
    it "builds a generic evaluation" do
      get :new
      expect(response).to be_success
      expect(assigns(:evaluation).type.to_sym).to eq :generic
    end
  end
end
