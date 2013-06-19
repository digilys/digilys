require 'spec_helper'

describe Template::SuitesController do
  login_admin

  describe "GET #index" do
    let!(:templates) { create_list(:suite, 2, is_template: true) }
    let!(:regular)   { create_list(:suite, 2, is_template: false) }

    it "lists suite templates" do
      get :index
      response.should be_success
      assigns(:suites).should match_array(templates)
    end
  end

  describe "GET #search" do
    let(:template) { create(:suite, is_template: true) }
    let!(:regular) { create(:suite, is_template: false, name: template.name) }

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
