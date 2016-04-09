require "csv"
require "digilys/evaluation_template_importer"

class Import::EvaluationTemplatesController < ApplicationController
  before_filter { authorize_import("evaluation_template") }

  def new
  end

  def confirm
    @filename = timestamp_prefix(params[:csv_file].original_filename)

    full_path = File.join(Rails.root, "tmp/uploads", @filename)
    FileUtils.cp params[:csv_file].path, full_path

    @importer = importer_for(full_path, params[:update])
  rescue => e
    logger.error(e.message)
    flash[:error] = t(:"import.evaluation_templates.create.error",:filename=>@filename,:errmsg=>e.message)
    redirect_to action: "new"
  end

  def create
    import_file = File.join(Rails.root, "tmp/uploads", params[:filename])

    unless File.exist?(import_file)
      render template: "shared/404", status: 404
      return
    end

    importer = importer_for(import_file, params[:update])

    if importer.valid?
      importer.import!
      flash[:success] = t(:"import.evaluation_templates.create.success", count: importer.valid_count)
      redirect_to template_evaluations_url()
    else
      flash[:error] = t(:"import.evaluation_templates.create.error", filename: params[:filename])
      redirect_to action: "new"
    end
  end


  private

  def importer_for(path, update)
    csv = CSV.open(path)
    Digilys::EvaluationTemplateImporter.new(csv, current_instance_id, update)
  end
end
