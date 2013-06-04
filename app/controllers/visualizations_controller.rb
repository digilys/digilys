class VisualizationsController < ApplicationController
  layout "fullpage"

  skip_authorization_check only: :filter

  before_filter :load_target

  def color_area_chart
    respond_to do |format|
      format.html
      format.json do
        render json: result_colors_to_datatable(evaluations)
      end
    end
  end

  def stanine_column_chart
    respond_to do |format|
      format.html
      format.json do
        render json: result_stanines_to_datatable(evaluations.with_stanines)
      end
    end
  end

  def result_line_chart
    respond_to do |format|
      format.html
      format.json do
        render json: results_to_datatable(evaluations)
      end
    end
  end


  def filter
    session[:visualization_filter] ||= {}
    session[:visualization_filter][:categories] = params[:filter_categories]
    redirect_to(params[:return_to] || root_url())
  end


  private

  def load_target
    if params[:suite_id]
      @suite = Suite.find(params[:suite_id])
      authorize! :update, @suite
      @entity = @suite
    end
  end

  def evaluations
    evaluations = @entity.evaluations

    if evaluations && session[:visualization_filter] && !session[:visualization_filter][:categories].blank?
      evaluations = evaluations.tagged_with(session[:visualization_filter][:categories], on: :categories)
    end

    return evaluations
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
        row << (evaluation.result_for(student).try(:value) || 0).to_f / evaluation.max_result.to_f
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

  def result_stanines_to_datatable(evaluations)
    rows = []
    rows << [ I18n.t(:stanine), I18n.t(:normal_distribution), *evaluations.collect(&:name) ]

    if evaluations.first
      num_participants = evaluations.first.participants.count(:all).to_f
    else
      num_participants = 0
    end

    # http://en.wikipedia.org/wiki/Stanine
    normal_distribution = {
      1 => 0.04 * num_participants,
      2 => 0.07 * num_participants,
      3 => 0.12 * num_participants,
      4 => 0.17 * num_participants,
      5 => 0.20 * num_participants,
      6 => 0.17 * num_participants,
      7 => 0.12 * num_participants,
      8 => 0.07 * num_participants,
      9 => 0.04 * num_participants
    }

    1.upto(9).each do |stanine|
      row = [ stanine.to_s, normal_distribution[stanine] ]
      evaluations.each { |e| row << (e.stanine_distribution[stanine] || 0) }
      rows << row
    end

    return rows
  end


end
