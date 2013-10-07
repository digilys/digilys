require 'spec_helper'

describe Template::EvaluationsController do
  login_user(:admin)

  let(:instance) { create(:instance) }

  describe "GET #index" do
    let!(:templates)      { create_list(:evaluation_template, 2) }
    let!(:others)         { create_list(:generic_evaluation,  2) }
    let!(:other_instance) { create(     :evaluation_template, instance: instance) }

    it "gives a list of generic evaluations" do
      get :index
      response.should be_success
      assigns(:evaluations).should match_array(templates)
    end
    it "is filterable" do
      get :index, q: { name_cont: templates.first.name }
      response.should be_success
      assigns(:evaluations).should == [templates.first]
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

      response.should be_success
      json = JSON.parse(response.body)

      json["more"].should be_false

      json["results"].should have(1).items
      json["results"].first.should include("id" =>          template.id)
      json["results"].first.should include("name" =>        template.name)
      json["results"].first.should include("description" => template.description)
    end
  end

  describe "GET #new" do
    it "builds a template evaluation" do
      get :new
      response.should be_success
      assigns(:evaluation).type.to_sym.should == :template
    end
  end
end
