require 'spec_helper'

describe Template::EvaluationsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance) { create(:instance) }

  describe "GET #index" do
    let!(:templates)      { create_list(:evaluation_template, 2) }
    let!(:others)         { create_list(:generic_evaluation,  2) }
    let!(:other_instance) { create(     :evaluation_template, instance: instance) }

    it "gives a list of generic evaluations" do
      get :index
      expect(response).to be_success
      expect(assigns(:evaluations)).to match_array(templates)
    end
    it "is filterable" do
      get :index, q: { name_cont: templates.first.name }
      expect(response).to be_success
      expect(assigns(:evaluations)).to eq [templates.first]
    end
  end

  describe "GET #search" do
    let(:template) { create(:evaluation_template) }
    let!(:other)   { [
        create(:evaluation_template),
        create(:generic_evaluation,  name: template.name),
        create(:evaluation_template, name: template.name, instance: instance)
    ] }

    it "returns matching template evaluations as json" do
      get :search, q: { name_cont: template.name }

      expect(response).to be_success
      json = JSON.parse(response.body)

      expect(json["more"]).to be_false

      expect(json["results"]).to have(1).items
      expect(json["results"].first).to include("id" =>          template.id)
      expect(json["results"].first).to include("name" =>        template.name)
      expect(json["results"].first).to include("description" => template.description)
    end
  end

  describe "GET #new" do
    it "builds a template evaluation" do
      get :new
      expect(response).to be_success
      expect(assigns(:evaluation).type.to_sym).to eq :template
    end
  end
end
