class Template::EvaluationsController < ApplicationController
  load_and_authorize_resource

  def index
    @evaluations = @evaluations.with_type(:template).order(:name).page(params[:page])
  end

  def search
    @evaluations   = @evaluations.order(:name).with_type(:template).search(params[:q]).result.page(params[:page])
    json           = {}
    json[:results] = @evaluations.collect { |e| { id: e.id, name: e.name, description: e.description } }
    json[:more]    = !@evaluations.last_page?

    render json: json.to_json
  end

  def new
    @evaluation.type = :template
  end
end
