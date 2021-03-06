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
      format.html do
        @evaluations = evaluations.with_stanines
      end
      format.json do
        if params[:evaluation_id]
          render json: result_stanines_by_color_to_datatable(Evaluation.find(params[:evaluation_id]))
        else
          render json: result_stanines_to_datatable(evaluations.with_stanines)
        end
      end
    end
  end

  def result_line_chart
    respond_to do |format|
      format.html
      format.json do
        render json: results_to_datatable(evaluations, @student)
      end
    end
  end


  def filter
    session[:visualization_filter] ||= {}
    session[:visualization_filter][params[:type].to_sym] ||= {}
    session[:visualization_filter][params[:type].to_sym][:categories] = params[:filter_categories]
    redirect_to(params[:return_to] || root_url())
  end


  private

  def load_target
    if params[:suite_id]
      @suite = Suite.where(instance_id: current_instance_id).find(params[:suite_id])
      authorize! :view, @suite
    elsif params[:student_id]
      @student = Student.where(instance_id: current_instance_id).find(params[:student_id])
      authorize! :show, @student
    end
  end

  def evaluations
    if @suite
      evaluations = @suite.evaluations
      type = :suite
    elsif @student
      evaluations = @student.suite_evaluations
      type = :student
    else
      return
    end

    if evaluations &&
        session[:visualization_filter] &&
        session[:visualization_filter][type] &&
        !session[:visualization_filter][type][:categories].blank?
      evaluations = evaluations.tagged_with(session[:visualization_filter][type][:categories], on: :categories)
    end

    return evaluations
  end

  ## Google Charts data transformers
  def results_to_datatable(evaluations, student = nil)
    rows = []

    if student
      students = [student]
    else
      students = evaluations.collect(&:students).flatten.uniq
    end

    # First row contains a dummy test name and the evaluation names
    rows << [ Evaluation.model_name.human(count: 2), *evaluations.collect { |e| "#{e.name} (#{e.date})" } ]

    students.each do |student|
      # One row per student, containing the name and the results
      row = []

      evaluations.each do |evaluation|
        result = evaluation.result_for(student)

        if result && result.value
          row << result.value.to_f / evaluation.max_result.to_f
        else
          row << nil
        end
      end

      # Add the student name, and do not add the row if there are only nil result values
      rows << row.unshift(student.name) if !row.compact.blank?
    end

    # Google Chart wants the columns to be the students and the
    # rows to be the evaluations to render a proper graph. We build
    # it the other way around, so now we transpose the array, flipping
    # it to the correct format.
    #
    # The reason for this is that it is much easier to check for
    # students which have only nil results above.
    return rows.transpose
  end

  def result_colors_to_datatable(evaluations)
    rows = []
    rows << [Evaluation.model_name.human(count: 2), I18n.t(:red), I18n.t(:yellow), I18n.t(:green) ]

    evaluations.each do |evaluation|
      result_distribution = evaluation.result_distribution

      if result_distribution.blank?
        rows << [
          "#{evaluation.name} (#{evaluation.date})",
          0,
          0,
          0
        ]
      else
        rows << [
          "#{evaluation.name} (#{evaluation.date})",
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
    rows << [ I18n.t(:stanine), I18n.t(:normal_distribution), *evaluations.collect { |e| "#{e.name} (#{e.date})" } ]

    if evaluations.first
      num_participants = evaluations.first.participant_count
    else
      num_participants = 0
    end

    normal_distribution = normal_distribution(num_participants)

    1.upto(9).each do |stanine|
      row = [ stanine.to_s, normal_distribution[stanine] ]
      evaluations.each { |e| row << (e.stanine_distribution[stanine] || 0) }
      rows << row
    end

    return rows
  end

  def result_stanines_by_color_to_datatable(evaluation)
    rows = []
    rows << [ I18n.t(:stanine), I18n.t(:normal_distribution), I18n.t(:red), I18n.t(:yellow), I18n.t(:green) ]

    return rows unless evaluation

    num_participants = evaluation.participant_count

    normal_distribution = normal_distribution(num_participants)

    stanine_distribution = evaluation.stanine_distribution

    data = {
      red:    stanine_distribution.select { |k, _| k && k < 4 },
      yellow: stanine_distribution.select { |k, _| k && k > 3 && k < 7 },
      green:  stanine_distribution.select { |k, _| k && k > 6 },
    }

    1.upto(9).each do |stanine|
      rows << [
        stanine.to_s,
        normal_distribution[stanine],
        data[:red][stanine]    || 0,
        data[:yellow][stanine] || 0,
        data[:green][stanine]  || 0,
      ]
    end

    return rows
  end

  def normal_distribution(max)
    # http://en.wikipedia.org/wiki/Stanine
    {
      1 => 0.04 * max,
      2 => 0.07 * max,
      3 => 0.12 * max,
      4 => 0.17 * max,
      5 => 0.20 * max,
      6 => 0.17 * max,
      7 => 0.12 * max,
      8 => 0.07 * max,
      9 => 0.04 * max
    }
  end

end
