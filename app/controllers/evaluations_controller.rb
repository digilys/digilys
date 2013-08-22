class EvaluationsController < ApplicationController
  before_filter :load_from_template, only: :new_from_template

  load_resource :suite
  load_resource :evaluation, through: :suite, shallow: true
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

    @evaluation.results.sort_by! { |r| r.student.name }
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
      authorize! :contribute_to, @suite
    elsif @evaluation.try(:suite)
      authorize! :contribute_to, @evaluation.suite
    elsif @evaluation
      authorize! params[:action].to_sym, @evaluation
    else
      authorize! params[:action].to_sym, Evaluation
    end
  end
end
