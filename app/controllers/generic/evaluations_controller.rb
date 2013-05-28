class Generic::EvaluationsController < ApplicationController
  layout "admin"
  load_and_authorize_resource

  def index
    @evaluations = @evaluations.with_type(:generic).order(:name).page(params[:page])
  end

  def new
    @evaluation.type = :generic
  end
end
