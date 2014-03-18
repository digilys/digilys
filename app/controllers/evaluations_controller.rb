class EvaluationsController < ApplicationController
  before_filter :load_from_template, only: :new_from_template

  load_and_authorize_resource :suite
  load_and_authorize_resource through: :suite, shallow: true

  before_filter :instance_filter


  def show
  end

  def new
    @evaluation.type = :suite
  end

  def new_from_template
    render action: "new"
  end

  def create
    @evaluation.instance = current_instance unless @evaluation.type.try(:suite?)

    if @evaluation.save
      flash[:success] = t(:"evaluations.create.success.#{@evaluation.type}")
      redirect_to @evaluation
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    params[:evaluation].delete(:instance)
    params[:evaluation].delete(:instance_id)

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

  def report
    @suite        = @evaluation.suite
    @participants = @evaluation.participants

    @participants.each do |participant|
      if !@evaluation.results.exists?(student_id: participant.student_id)
        @evaluation.results.build(student_id: participant.student_id)
      end
    end

    first, second = current_name_order.split(/\s*,\s*/)

    @evaluation.results.sort_by! { |r| r.student.send(first) + r.student.send(second) }
  end
  def report_all
    if params[:ids].blank?
      redirect_to @suite
    elsif params[:ids].length == 1
      redirect_to report_evaluation_url(params[:ids].first)
    else
      @evaluations = Evaluation.order(:date).find(params[:ids])

      @participants = {}

      @evaluations.each do |evaluation|
        evaluation.participants.each do |participant|
          unless evaluation.results.detect { |r| r.student_id == participant.student_id }
            evaluation.results.build(student_id: participant.student_id)
          end

          @participants[participant.id] = participant unless @participants.has_key?(participant.id)
        end
      end

      @participants = @participants.values
      @participants.sort_by!(&:name)
    end
  end

  def submit_report
    @suite        = @evaluation.suite
    @participants = @suite.participants

    if @evaluation.update_attributes(params[:evaluation])
      flash[:success] = t(:"evaluations.submit_report.success")
      redirect_to @suite
    else
      render action: "report"
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

  # Loads an entity from a template id.
  # Required as a before_filter so it works with cancan's auth
  def load_from_template
    template    = Evaluation.find(params[:evaluation][:template_id])
    @evaluation = Evaluation.new_from_template(template, params[:evaluation])
  end

  def instance_filter
    if suite = @evaluation.try(:suite) || @suite
      raise ActiveRecord::RecordNotFound if suite.instance_id != current_instance_id
    elsif @evaluation && !@evaluation.new_record?
      raise ActiveRecord::RecordNotFound if @evaluation.instance_id != current_instance_id
    end
  end
end
