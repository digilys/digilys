require 'csv'

class EvaluationsController < ApplicationController
  before_filter :load_from_template, only: :new_from_template

  load_and_authorize_resource :suite
  load_and_authorize_resource through: :suite, shallow: true
  skip_load_resource :only => :restore

  before_filter :instance_filter


  def search
    search_params = Hash[
      params[:q].collect do |k, v|
        [k, v.include?(",") ? v.split(/\s*,\s*/) : v ]
      end
    ]

    @evaluations = @evaluations.
      select("evaluations.id, evaluations.name, suites.name as suite_name").
      search_in_instance(current_instance_id, search_params).
      where([ "(suites.is_template is null or suites.is_template = ?)", false ]).
      with_type(:generic, :suite).order("evaluations.name").
      page(params[:page])

    json           = {}
    json[:results] = @evaluations.collect { |e| { id: e.id, text: "#{e.name}#{", #{e.suite_name}" if e.suite_name}" } }
    json[:more]    = !@evaluations.last_page?

    render json: json.to_json
  end

  def show
  end

  def new
    @evaluation.type = :suite
  end

  def new_from_template
    if params[:evaluation][:template_id].split(",").length > 1
      if @evaluation.suite.is_template?
        create
      else
        render action: "new"
      end
    else
      render action: "new"
    end
  end

  def create
    if params[:evaluation][:template_id] && params[:evaluation][:template_id].split(",").length > 1
      params[:evaluation][:template_id].split(",").each do |id|
        load_from_template(id)
        @evaluation.instance = current_instance unless @evaluation.type.try(:suite?)
        @evaluation.save
      end
      flash[:success] = t(:"evaluations.create.success.#{@evaluation.type}")
      redirect_to @evaluation.suite
    else
      @evaluation.instance = current_instance unless @evaluation.type.try(:suite?)

      if @evaluation.save
        flash[:success] = t(:"evaluations.create.success.#{@evaluation.type}")
        redirect_to @evaluation
      else
        render action: "new"
      end
    end
  end

  def edit
  end

  def update
    params[:evaluation].delete(:instance)
    params[:evaluation].delete(:instance_id)

    params[:evaluation][:user_ids] = params[:evaluation][:user_ids].split(",") unless params[:evaluation].nil? or params[:evaluation][:user_ids].nil?

    if @evaluation.update_attributes(params[:evaluation])
      flash[:success] = t(:"evaluations.update.success.#{@evaluation.type}")
      redirect_to @evaluation
    else
      render action: "edit"
    end
  end

  def confirm_destroy
  end
  def destroy
    @evaluation.destroy

    flash[:success] = t(:"evaluations.destroy.success.#{@evaluation.type}")

    case @evaluation.type.to_sym
    when :suite
      redirect_to @evaluation.suite
    when :template
      redirect_to template_evaluations_url()
    when :generic
      redirect_to generic_evaluations_url()
    end
  end

  def restore
    evaluation = Evaluation.find_in_trash(params[:id])
    evaluation.restore
    flash[:success] = t(:"evaluations.restore.success.#{evaluation.type}")
    redirect_to trash_index_path
  end

  def report
    @suite        = @evaluation.suite
    @groups = result_groups([@evaluation])
  end

  def report_all
    if params[:ids].blank?
      redirect_to @suite
    elsif params[:ids].length == 1
      redirect_to report_evaluation_url(params[:ids].first)
    else
      @evaluations = Evaluation.order(:date).find(params[:ids])
      @groups = result_groups(@evaluations)
    end
  end

  def submit_report_all
    params[:results].each do |evaluation_id, students|
      evaluation = Evaluation.find(evaluation_id)

      students.each do |student_id, value|
        result = evaluation.results.detect { |r| r.student_id == student_id.to_i }
        result ||= evaluation.results.build(student_id: student_id.to_i)

        if value.blank? && !result.new_record?
          result.destroy
        elsif value == "absent"
          result.absent = true
          result.value = nil
          result.save
        else
          result.absent = false
          result.value = value
          result.save
        end
      end
    end

    flash[:success] = t(:"evaluations.submit_report.success")
    redirect_to(@suite)
  end

  def destroy_report
    @evaluation.results.clear
    flash[:success] = t(:"evaluations.destroy_report.success")
    redirect_to report_evaluation_url(@evaluation)
  end


  private

  def result_groups(evaluations)
    participants = {}

    evaluations.each do |evaluation|
      evaluation.participants.each do |participant|
        unless evaluation.results.detect { |r| r.student_id == participant.student_id }
          evaluation.results.build(student_id: participant.student_id)
        end

        group = participant.group.name unless participant.group.nil?

        participants[group] = [] if participants[group].nil?
        participants[group] << participant unless participants[group].include?(participant)
      end
    end
    return participants
  end

  # Loads an entity from a template id.
  # Required as a before_filter so it works with cancan's auth
  def load_from_template(id=nil)
    ids = params[:evaluation][:template_id].split(",")
    @suite = Suite.find(params[:evaluation][:suite_id])
    if ids.size > 1 && !@suite.is_template?
      @evaluations = []
      ids.each do |i|
        template    = Evaluation.find(i)
        evaluation = Evaluation.new_from_template(template, params[:evaluation])
        evaluation.instance = current_instance unless evaluation.type.try(:suite?)
        evaluation.save
        @suite.evaluations.build(name: evaluation.name) unless @suite.is_template?
        @evaluations << evaluation
      end
      @evaluation = @evaluations.first
    else
      id ||= params[:evaluation][:template_id]
      template    = Evaluation.find(id)
      @evaluation = Evaluation.new_from_template(template, params[:evaluation])
    end
  end

  def report_params
    params.require(:evaluation).permit(:result_file)
  end

  def instance_filter
    if suite = @evaluation.try(:suite) || @suite
      raise ActiveRecord::RecordNotFound if suite.instance_id != current_instance_id
    elsif @evaluation && !@evaluation.new_record?
      raise ActiveRecord::RecordNotFound if @evaluation.instance_id != current_instance_id
    end
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
