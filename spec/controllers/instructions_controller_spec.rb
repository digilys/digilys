require 'spec_helper'

describe InstructionsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  let(:instruction) { create(:instruction) }

  describe "GET #index" do
    let!(:instructions) { create_list(:instruction, 2) }

    it "lists instructions" do
      get :index
      expect(response).to be_successful
      expect(assigns(:instructions)).to match_array(instructions)
    end
  end

  describe "GET #export" do
    let!(:instruction) { create(:instruction) }

    it "exports instructions as json" do
      get :export
      expect(response).to be_successful
      result = Yajl::Parser.parse(response.body)
      expect(result["_id"]).to eq "export-#{instruction.id}"
    end
  end

  describe "GET #new" do
    it "sets the for_page parameter" do
      get :new, for_page: "/foo/bar"
      expect(response).to be_success
      expect(assigns(:instruction).for_page).to eq "/foo/bar"
    end
  end
  describe "POST #create" do
    it "redirects to the return parameter when successful" do
      post :create, instruction: valid_parameters_for(:instruction), return_to: "/return/to"
      expect(response).to redirect_to("/return/to")
    end
    it "redirects to the root url if no return parameter is set" do
      post :create, instruction: valid_parameters_for(:instruction)
      expect(response).to redirect_to(root_url())
    end
    it "renders the new page if the instruction is invalid" do
      post :create, instruction: invalid_parameters_for(:instruction)
      expect(response).to render_template("new")
    end
  end

  describe "GET #edit" do
    it "is successful" do
      get :edit, id: instruction.id
      expect(response).to be_success
    end
  end
  describe "PUT #update" do
    it "redirects to the return parameter when successful" do
      new_title = "#{instruction.title} updated"
      put :update, id: instruction.id, instruction: { title: new_title }, return_to: "/return/to"
      expect(response).to redirect_to("/return/to")
      expect(instruction.reload.title).to eq new_title
    end
    it "redirects to the root url if no return parameter is set" do
      put :update, id: instruction.id, instruction: { title: "#{instruction.title} updated" }
      expect(response).to redirect_to(root_url())
    end
    it "renders the edit page if the instruction is invalid" do
      put :update, id: instruction.id, instruction: invalid_parameters_for(:instruction)
      expect(response).to render_template("edit")
    end
  end

  describe "GET #confirm_destroy" do
    it "is successful" do
      get "confirm_destroy", id: instruction.id
      expect(response).to be_success
    end
  end
  describe "DELETE #destroy" do
    it "redirects to the return parameter" do
      delete "destroy", id: instruction.id, return_to: "/return/to"
      expect(response).to redirect_to("/return/to")
      expect(Instruction.exists?(instruction.id)).to be_false
    end
    it "redirects to the root url if no return parameter is set" do
      delete "destroy", id: instruction.id
      expect(response).to redirect_to(root_url())
    end
  end
end
