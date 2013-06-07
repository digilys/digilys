class Template::SuitesController < ApplicationController
  load_and_authorize_resource

  def index
    @suites = @suites.template.order(:name).page(params[:page])
  end

  def search
    @suites = @suites.template.page(params[:page]).search(params[:q]).result
    render json: @suites.collect { |s| { id: s.id, text: s.name } }.to_json
  end

  def new
    @suite.is_template = true
    render template: "suites/new"
  end
end
