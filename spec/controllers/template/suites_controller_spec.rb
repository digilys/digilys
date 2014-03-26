require 'spec_helper'

describe Template::SuitesController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instance) { create(:instance) }

  describe "GET #index" do
    let!(:templates)      { create_list(:suite, 2, is_template: true) }
    let!(:regular)        { create_list(:suite, 2, is_template: false) }
    let!(:other_instance) { create(     :suite,    is_template: true, instance: instance) }

    it "lists suite templates" do
      get :index
      expect(response).to be_success
      expect(assigns(:suites)).to match_array(templates)
    end
    it "should be filterable" do
      get :index, q: { name_cont: templates.first.name }
      expect(response).to be_success
      expect(assigns(:suites)).to eq [templates.first]
    end
  end

  describe "GET #search" do
    let(:template)        { create(:suite, is_template: true) }
    let!(:regular)        { create(:suite, is_template: false, name: template.name) }
    let!(:other_instance) { create(:suite, is_template: true,  name: template.name, instance: instance) }

    it "returns matching template evaluations as json" do
      get :search, q: { name_cont: template.name }

      expect(response).to be_success
      json = JSON.parse(response.body)

      expect(json["more"]).to be_false

      expect(json["results"]).to have(1).items
      expect(json["results"].first).to include("id"   => template.id)
      expect(json["results"].first).to include("text" => template.name)
    end
  end

  describe "GET #new" do
    it "initializes a new template suite" do
      get :new

      expect(response).to be_success
      expect(response).to render_template("suites/new")

      expect(assigns(:suite).is_template).to be_true
    end
  end
end
