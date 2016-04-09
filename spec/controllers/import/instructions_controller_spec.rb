require 'spec_helper'

describe Import::InstructionsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  describe "GET #new" do
    it "is successful" do
      get :new
      expect(response).to be_success
    end

    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns 401" do
        get :new
        expect(response.status).to be 401
      end
    end

  end
  describe "POST #confirm" do
    let(:first_object)   { { "foo" => 1 } }
    let(:second_object)  { { "bar" => 2 } }
    let(:export_file_io) { first_object.to_json + second_object.to_json }

    it "parses JSON data from the incoming file" do
      post :confirm, export_file: export_file_io
      expect(response).to be_success
      expect(assigns(:uploaded_instructions)).to include(first_object)
      expect(assigns(:uploaded_instructions)).to include(second_object)
    end
    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns 401" do
        post :confirm, export_file: export_file_io
        expect(response.status).to be 401
      end
    end
  end
  describe "POST #create" do
    let(:new_instruction1) { attributes_for(:instruction).merge(import: 1) }
    let(:new_instruction2) { attributes_for(:instruction).merge(import: 1) }

    it "redirects to the instruction index url" do
      post :create, instructions: []
      expect(response).to redirect_to(instructions_url())
    end
    it "creates new instructions from incoming data" do
      expect(Instruction.count).to eq 0

      post :create, instructions: { 0 => new_instruction1, 1 => new_instruction2 }

      expect(Instruction.count).to eq 2

      instruction = Instruction.where(for_page: new_instruction1[:for_page]).first
      expect(instruction.for_page).to    eq new_instruction1[:for_page]
      expect(instruction.title).to       eq new_instruction1[:title]
      expect(instruction.film).to        eq new_instruction1[:film]
      expect(instruction.description).to eq new_instruction1[:description]

      instruction = Instruction.where(for_page: new_instruction2[:for_page]).first
      expect(instruction.for_page).to    eq new_instruction2[:for_page]
      expect(instruction.title).to       eq new_instruction2[:title]
      expect(instruction.film).to        eq new_instruction2[:film]
      expect(instruction.description).to eq new_instruction2[:description]
    end
    it "skips instructions that don't have an import flag set" do
      expect(Instruction.count).to eq 0
      post :create, instructions: { 0 => new_instruction1.merge(import: false) }
      expect(Instruction.count).to eq 0
    end
    it "updates existing instructions" do
      existing = create(:instruction)

      post :create, instructions: { 0 => new_instruction1.merge(existing_id: existing.id) }

      existing.reload

      expect(existing.for_page).to eq new_instruction1[:for_page]
      expect(existing.title).to    eq new_instruction1[:title]
    end
    context "as instance admin" do
      login_user(:user)
      before(:each) do
        logged_in_user.admin_instance = logged_in_user.active_instance
        logged_in_user.save
      end
      it "returns 401" do
        post :create, instructions: { 0 => new_instruction1, 1 => new_instruction2 }
        expect(response.status).to be 401
      end
    end
  end
end
