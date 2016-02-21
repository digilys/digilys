class Template::EvaluationsController < ApplicationController
  load_and_authorize_resource

  before_filter :instance_filter

  def index
    @evaluations = @evaluations.with_type(:template)
    @evaluations = @evaluations.search(params[:q]).result        if has_search_param?
    @evaluations = @evaluations.order(:name).page(params[:page])
  end

  def search
    @evaluations   = @evaluations.order(:name).with_type(:template).search(params[:q]).result.page(params[:page])
    json           = {}
    json[:results] = @evaluations.collect { |e| { id: e.id, text: e.name, name: e.name, description: e.description } }
    json[:more]    = !@evaluations.last_page?

    render json: json.to_json
  end

  def new
    @evaluation.type = :template
  end


  private

  def instance_filter
    @evaluations = @evaluations.where(instance_id: current_instance_id) if @evaluations
  end
end
