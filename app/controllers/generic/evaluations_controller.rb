class Generic::EvaluationsController < ApplicationController
  load_and_authorize_resource

  def index
    @evaluations = @evaluations.with_type(:generic).order(:name)
    @evaluations = @evaluations.search(params[:q]).result        if has_search_param?
    @evaluations = @evaluations.page(params[:page])
  end

  def new
    @evaluation.type = :generic
  end
end
