require 'spec_helper'

describe Import::InstructionsController, versioning: !ENV["debug_versioning"].blank? do
  debug_versioning(ENV["debug_versioning"]) if ENV["debug_versioning"]

  login_user(:admin)

  describe "GET #new" do
    it "is successful" do
      get :new
      response.should be_success
    end
  end
  describe "POST #confirm" do
    let(:first_object)   { { "foo" => 1 } }
    let(:second_object)  { { "bar" => 2 } }
    let(:export_file_io) { first_object.to_json + second_object.to_json }

    it "parses JSON data from the incoming file" do
      post :confirm, export_file: export_file_io
      response.should be_success
      assigns(:uploaded_instructions).should include(first_object)
      assigns(:uploaded_instructions).should include(second_object)
    end
  end
  describe "POST #create" do
    let(:new_instruction1) { attributes_for(:instruction).merge(import: 1) }
    let(:new_instruction2) { attributes_for(:instruction).merge(import: 1) }

    it "redirects to the instruction index url" do
      post :create, instructions: []
      response.should redirect_to(instructions_url())
    end
    it "creates new instructions from incoming data" do
      Instruction.count.should == 0

      post :create, instructions: { 0 => new_instruction1, 1 => new_instruction2 }

      Instruction.count.should == 2

      instruction = Instruction.where(for_page: new_instruction1[:for_page]).first
      instruction.for_page.should    == new_instruction1[:for_page]
      instruction.title.should       == new_instruction1[:title]
      instruction.film.should        == new_instruction1[:film]
      instruction.description.should == new_instruction1[:description]

      instruction = Instruction.where(for_page: new_instruction2[:for_page]).first
      instruction.for_page.should    == new_instruction2[:for_page]
      instruction.title.should       == new_instruction2[:title]
      instruction.film.should        == new_instruction2[:film]
      instruction.description.should == new_instruction2[:description]
    end
    it "skips instructions that don't have an import flag set" do
      Instruction.count.should == 0
      post :create, instructions: { 0 => new_instruction1.merge(import: false) }
      Instruction.count.should == 0
    end
    it "updates existing instructions" do
      existing = create(:instruction)

      post :create, instructions: { 0 => new_instruction1.merge(existing_id: existing.id) }

      existing.reload

      existing.for_page.should == new_instruction1[:for_page]
      existing.title.should    == new_instruction1[:title]
    end
  end
end
