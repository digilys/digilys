class VisualizationsController < ApplicationController
  layout "fullpage"

  before_filter :load_target

  def color_area_chart
    respond_to do |format|
      format.html
      format.json do
        render json: result_colors_to_datatable(@entity.evaluations)
      end
    end
  end


  private

  def load_target
    if params[:suite_id]
      @suite = Suite.find(params[:suite_id])
      authorize! :update, @suite
      @entity = @suite
    end
  end

  ## Google Charts data transformers
  def results_to_datatable(evaluations)
    rows = []

    students = evaluations.collect(&:students).flatten.uniq

    # Title row
    rows << [ Evaluation.model_name.human(count: 2), *students.collect(&:name) ]

    # Rows for results
    evaluations.each do |evaluation|
      row = [ evaluation.name ]

      students.each do |student|
        row << evaluation.result_for(student).try(:value)
      end

      rows << row
    end

    return rows
  end

  def result_colors_to_datatable(evaluations)
    rows = []
    rows << [Evaluation.model_name.human(count: 2), I18n.t(:red), I18n.t(:yellow), I18n.t(:green) ]

    evaluations.each do |evaluation|
      result_distribution = evaluation.result_distribution

      if result_distribution.blank?
        rows << [
          evaluation.name,
          0,
          0,
          0
        ]
      else
        rows << [
          evaluation.name,
          result_distribution[:red], 
          result_distribution[:yellow],
          result_distribution[:green]
        ]
      end
    end

    return rows
  end


end
