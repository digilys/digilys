class EvaluationsController < ApplicationController
  layout "admin"

  def new
    @suite            = Suite.find(params[:suite_id])
    @evaluation       = Evaluation.new
    @evaluation.suite = @suite
  end

  # A suite id is required, so we load it separately
  # in order to cause a 404 if it doesn't exist
  def create
    @suite      = Suite.find(params[:evaluation][:suite_id])
    @evaluation = Evaluation.new(params[:evaluation])

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
    redirect_to suite
  end
end
