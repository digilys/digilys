class Import::InstructionsController < ApplicationController
  before_filter { authorize_import("instructions") }

  def new
  end

  def confirm
    @uploaded_instructions = []
    Yajl::Parser.parse(params[:export_file]) { |obj| @uploaded_instructions << obj }
  end

  def create
    params[:instructions].each do |_, incoming|
      next unless incoming[:import]

      instruction = if incoming[:existing_id]
        Instruction.find(incoming[:existing_id])
      else
        Instruction.new
      end

      instruction.title       = incoming[:title]
      instruction.for_page    = incoming[:for_page]
      instruction.film        = incoming[:film]
      instruction.description = incoming[:description]

      instruction.save!
    end

    flash[:success] = t(:"import.instructions.create.success")
    redirect_to instructions_url()
  end

end
