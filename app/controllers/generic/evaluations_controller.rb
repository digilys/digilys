class Generic::EvaluationsController < ApplicationController
  load_and_authorize_resource

  before_filter :instance_filter

  def index
    @evaluations = @evaluations.with_type(:generic).order(:name)
    @evaluations = @evaluations.search(params[:q]).result        if has_search_param?
    @evaluations = @evaluations.page(params[:page])
  end

  def new
    @evaluation.type = :generic
  end


  private

  def instance_filter
    @evaluations = @evaluations.where(instance_id: current_instance_id) if @evaluations
  end
end
