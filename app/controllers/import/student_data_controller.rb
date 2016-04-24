require "csv"
require "digilys/excel_converter"
require "digilys/student_data_importer"

class Import::StudentDataController < ApplicationController
  before_filter { authorize_import("student_data") }

  def new
  end

  def confirm
    @filename = "#{Time.zone.now.to_s(ActiveRecord::Base.cache_timestamp_format)}-#{params[:excel_file].original_filename}.tsv"
    full_path = File.join(Rails.root, "tmp/uploads", @filename)

    Digilys::ExcelConverter.convert_student_data_file(
      params[:excel_file].path,
      full_path,
      File.extname(params[:excel_file].original_filename)
    )

    @importer = importer_for(full_path)
  rescue => e
    logger.error(e.message)
    flash[:error] = t(:"import.student_data_controller.confirm.error")
    redirect_to action: "new"
  end

  def create
    import_file = File.join(Rails.root, "tmp/uploads", params[:filename])

    unless File.exist?(import_file)
      render template: "shared/404", status: 404
      return
    end

    importer = importer_for(import_file)

    if importer.valid?
      importer.import!
      flash[:success] = t(:"import.student_data.create.success", count: importer.valid_count)
      redirect_to students_url()
    else
      flash[:error] = t(:"import.student_data.create.error", filename: params[:filename])
      redirect_to action: "new"
    end
  end


  private

  def importer_for(path)
    tsv = CSV.open(path, col_sep: "\t")
    Digilys::StudentDataImporter.new(tsv, current_instance_id)
  end
end
