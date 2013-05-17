class EvaluationsController < ApplicationController
  layout "admin"

  before_filter :load_from_template, only: :new_from_template
  load_and_authorize_resource

  def index
    @evaluations = @evaluations.templates.order(:name).page(params[:page])
  end

  def search
    @evaluations = @evaluations.templates.page(params[:page]).search(params[:q]).result
    render json: @evaluations.collect { |e| { id: e.id, text: e.name } }.to_json
  end

  def show
  end

  def new
    @evaluation.suite = Suite.find(params[:suite_id]) if params[:suite_id]
  end

  def new_from_template
    render action: "new"
  end

  def create
    unless params[:evaluation][:suite_id].blank?
      suite             = Suite.find(params[:evaluation].delete(:suite_id))
      @evaluation.suite = suite
    end

    if @evaluation.save
      flash[:success] = t(:"evaluations.create.success")
      redirect_to @evaluation
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    if @evaluation.update_attributes(params[:evaluation])
      flash[:success] = t(:"evaluations.update.success")
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

    flash[:success] = t(:"evaluations.destroy.success")
    if suite
      redirect_to suite
    else
      redirect_to evaluations_url()
    end
  end

  def report
    @suite        = @evaluation.suite
    @participants = @suite.participants

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


  private

  # Loads an entity from a template id.
  # Required as a before_filter so it works with cancan's auth
  def load_from_template
    template    = Evaluation.find(params[:evaluation][:template_id])
    @evaluation = Evaluation.new_from_template(template, params[:evaluation])
  end
end
