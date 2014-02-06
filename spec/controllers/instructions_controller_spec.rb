require 'spec_helper'

describe InstructionsController do
  login_user(:admin)

  let(:instruction) { create(:instruction) }

  describe "GET #index" do
    let!(:instructions) { create_list(:instruction, 2) }

    it "lists instructions" do
      get :index
      response.should be_successful
      assigns(:instructions).should match_array(instructions)
    end
  end

  describe "GET #export" do
    let!(:instruction) { create(:instruction) }

    it "exports instructions as json" do
      get :export
      response.should be_successful
      result = Yajl::Parser.parse(response.body)
      result["_id"].should == "export-#{instruction.id}"
    end
  end

  describe "GET #new" do
    it "sets the for_page parameter" do
      get :new, for_page: "/foo/bar"
      response.should be_success
      assigns(:instruction).for_page.should == "/foo/bar"
    end
  end
  describe "POST #create" do
    it "redirects to the return parameter when successful" do
      post :create, instruction: valid_parameters_for(:instruction), return_to: "/return/to"
      response.should redirect_to("/return/to")
    end
    it "redirects to the root url if no return parameter is set" do
      post :create, instruction: valid_parameters_for(:instruction)
      response.should redirect_to(root_url())
    end
    it "renders the new page if the instruction is invalid" do
      post :create, instruction: invalid_parameters_for(:instruction)
      response.should render_template("new")
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: instruction.id
      response.should be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the return parameter when successful" do
      new_title = "#{instruction.title} updated"
      put :update, id: instruction.id, instruction: { title: new_title }, return_to: "/return/to"
      response.should redirect_to("/return/to")
      instruction.reload.title.should == new_title
    end
    it "redirects to the root url if no return parameter is set" do
      put :update, id: instruction.id, instruction: { title: "#{instruction.title} updated" }
      response.should redirect_to(root_url())
    end
    it "renders the edit page if the instruction is invalid" do
      put :update, id: instruction.id, instruction: invalid_parameters_for(:instruction)
      response.should render_template("edit")
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get "confirm_destroy", id: instruction.id
      response.should be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the return parameter" do
      delete "destroy", id: instruction.id, return_to: "/return/to"
      response.should redirect_to("/return/to")
      Instruction.exists?(instruction.id).should be_false
    end
    it "redirects to the root url if no return parameter is set" do
      delete "destroy", id: instruction.id
      response.should redirect_to(root_url())
    end
  end
end
