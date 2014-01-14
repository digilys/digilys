require "digilys/exporter"

class InstructionsController < ApplicationController
  layout "fullpage"

  load_and_authorize_resource

  def index
    @instructions = @instructions.order(:title)
  end

  def export
    exporter = Digilys::Exporter.new("export")
    io       = StringIO.new

    exporter.export_instructions(io)

    send_data(
      io.string,
      filename: "instructions.json",
      type:     "application/json"
    )
  end

  def new
    @instruction.for_page = params[:for_page]
  end

  def create
    if @instruction.save
      flash[:success] = t(:"instructions.create.success")
      redirect_to params[:return_to] || root_url()
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    if @instruction.update_attributes(params[:instruction])
      flash[:success] = t(:"instructions.update.success")
      redirect_to params[:return_to] || root_url()
    else
      render action: "edit"
    end
  end

  def confirm_destroy
  end

  def destroy
    @instruction.destroy
    flash[:success] = t(:"instructions.destroy.success")
    redirect_to params[:return_to] || root_url()
  end
end
