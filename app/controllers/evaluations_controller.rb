class EvaluationsController < ApplicationController
  layout "admin"

  before_filter :load_from_template, only: :new_from_template

  load_and_authorize_resource :suite
  load_and_authorize_resource :evaluation, through: :suite, shallow: true
  before_filter :authorize_suite!


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
    suite = @evaluation.suite
    @evaluation.destroy

    flash[:success] = t(:"evaluations.destroy.success.#{@evaluation.type}")
    if suite
      redirect_to suite
    else
      redirect_to evaluations_url()
    end
  end

  def report
    @suite        = @evaluation.suite

    case @evaluation.target
    when "all"
      @participants = @suite.participants
    else
      @participants = @suite.participants.with_gender(@evaluation.target)
    end

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

  def authorize_suite!
    if @evaluation.try(:suite)
      authorize! :update, @evaluation.suite
    end
  end
end
