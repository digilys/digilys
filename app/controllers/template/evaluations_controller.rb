class Template::EvaluationsController < ApplicationController
  load_and_authorize_resource

  def index
    @evaluations = @evaluations.with_type(:template).order(:name).page(params[:page])
  end

  def search
    @evaluations = @evaluations.with_type(:template).page(params[:page]).search(params[:q]).result
    render json: @evaluations.collect { |e| { id: e.id, text: e.name } }.to_json
  end

  def new
    @evaluation.type = :template
  end
end
