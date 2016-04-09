require "csv"
require "digilys/result_importer"

class Import::ResultController < ApplicationController
  before_filter { authorize_import("result") }

  def new
    @suites = Suite.where(instance_id: current_user.active_instance_id, is_template: false).order(:name).all
    if params[:suites]
      @selected_suite = Suite.find(params[:suites])
    else
      @selected_suite = Suite.first
    end
    @evaluations = @selected_suite.evaluations.order(:name)
  end

  def confirm
    @evaluation = Evaluation.find(params[:evaluation])
    @participants = @evaluation.participants
    @results = @evaluation.results

    @filename = timestamp_prefix(params[:csv_file].original_filename)

    full_path = File.join(Rails.root, "tmp/uploads", @filename)
    FileUtils.cp params[:csv_file].path, full_path

    @importer = importer_for(full_path, params[:evaluation], params[:update])
  rescue => e
    logger.error(e.message)
    flash[:error] = t(:"import.result.confirm.error")
    redirect_to action: "new"
  end

  def create
    import_file = File.join(Rails.root, "tmp/uploads", params[:filename])

    unless File.exist?(import_file)
      render template: "shared/404", status: 404
      return
    end

    importer = importer_for(import_file, params[:evaluation], params[:update])

    if importer.valid?
      importer.import!
      flash[:success] = t(:"import.result.create.success", count: importer.valid_count)
      if can? :view, Evaluation.find(params[:evaluation]).suite
        redirect_to url_for(Evaluation.find(params[:evaluation]).suite)
      else
        redirect_to root_url()
      end
    else
      flash[:error] = t(:"import.result.create.error", filename: params[:filename])
      redirect_to action: "new"
    end
  end


  private

    def importer_for(path, evaluation_id, update)
      csv = CSV.open(path)
      Digilys::ResultImporter.new(csv, evaluation_id, update)
    end

    def format_participants(participants)
        participants.each do |participant|
          if !@evaluation.results.exists?(student_id: participant.student_id)
            @evaluation.results.build(student_id: participant.student_id)
          end
        end

        first, second = current_name_order.split(/\s*,\s*/)

        @evaluation.results.sort_by! { |r| r.student.send(first) + r.student.send(second) }
    end
end
