class EvaluationsController < ApplicationController
  layout "admin"

  def index
    @evaluations = Evaluation.templates.order(:name).page(params[:page])
  end

  def search
    @evaluations = Evaluation.templates.page(params[:page]).search(params[:q]).result
    render json: @evaluations.collect { |e| { id: e.id, text: e.name } }.to_json
  end

  def show
    @evaluation = Evaluation.find(params[:id])
  end

  def new
    @evaluation       = Evaluation.new
    @evaluation.suite = Suite.find(params[:suite_id]) if params[:suite_id]
  end

  def new_from_template
    template    = Evaluation.find(params[:evaluation][:template_id])
    @evaluation = Evaluation.new_from_template(template, params[:evaluation])

    render action: "new"
  end

  def create
    suite             = Suite.find(params[:evaluation].delete(:suite_id)) unless params[:evaluation][:suite_id].blank?
    @evaluation       = Evaluation.new(params[:evaluation])
    @evaluation.suite = suite

    if @evaluation.save
      flash[:success] = t(:"evaluations.create.success")
      redirect_to @evaluation
    else
      render action: "new"
    end
  end

  def edit
    @evaluation = Evaluation.find(params[:id])
  end

  def update
    @evaluation = Evaluation.find(params[:id])

    if @evaluation.update_attributes(params[:evaluation])
      flash[:success] = t(:"evaluations.update.success")
      redirect_to @evaluation
    else
      render action: "edit"
    end
  end

  def confirm_destroy
    @evaluation = Evaluation.find(params[:id])
  end
  def destroy
    evaluation = Evaluation.find(params[:id])
    suite = evaluation.suite
    evaluation.destroy

    flash[:success] = t(:"evaluations.destroy.success")
    if suite
      redirect_to suite
    else
      redirect_to evaluations_url()
    end
  end

  def report
    @evaluation   = Evaluation.find(params[:id])
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
    @evaluation   = Evaluation.find(params[:id])
    @suite        = @evaluation.suite
    @participants = @suite.participants

    if @evaluation.update_attributes(params[:evaluation])
      flash[:success] = t(:"evaluations.submit_report.success")
      redirect_to @suite
    else
      render action: "report"
    end
  end
end
