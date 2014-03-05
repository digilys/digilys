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
      response.should be_success
      assigns(:suites).should match_array(templates)
    end
    it "should be filterable" do
      get :index, q: { name_cont: templates.first.name }
      response.should be_success
      assigns(:suites).should == [templates.first]
    end
  end

  describe "GET #search" do
    let(:template)        { create(:suite, is_template: true) }
    let!(:regular)        { create(:suite, is_template: false, name: template.name) }
    let!(:other_instance) { create(:suite, is_template: true,  name: template.name, instance: instance) }

    it "returns matching template evaluations as json" do
      get :search, q: { name_cont: template.name }

      response.should be_success
      json = JSON.parse(response.body)

      json["more"].should be_false

      json["results"].should have(1).items
      json["results"].first.should include("id"   => template.id)
      json["results"].first.should include("text" => template.name)
    end
  end

  describe "GET #new" do
    it "initializes a new template suite" do
      get :new

      response.should be_success
      response.should render_template("suites/new")

      assigns(:suite).is_template.should be_true
    end
  end
end
