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
end
