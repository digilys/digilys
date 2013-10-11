class EvaluationsController < ApplicationController
  before_filter :load_from_template, only: :new_from_template

  load_resource :suite
  load_resource :evaluation, through: :suite, shallow: true

  before_filter :instance_filter
  before_filter :authorize_evaluation!


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

  def authorize_evaluation!
    if @suite
      authorize! :change, @suite
    elsif @evaluation.try(:suite)
      authorize! :change, @evaluation.suite
    elsif @evaluation
      authorize! params[:action].to_sym, @evaluation
    else
      authorize! params[:action].to_sym, Evaluation
    end
  end

  def instance_filter
    if suite = @evaluation.try(:suite) || @suite
      raise ActiveRecord::RecordNotFound if suite.instance_id != current_instance_id
    elsif @evaluation && !@evaluation.new_record?
      raise ActiveRecord::RecordNotFound if @evaluation.instance_id != current_instance_id
    end
  end
end
