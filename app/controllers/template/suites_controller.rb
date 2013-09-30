class Template::SuitesController < ApplicationController
  load_and_authorize_resource

  before_filter :instance_filter

  def index
    @suites = @suites.template.order(:name)
    @suites = @suites.search(params[:q]).result if has_search_param?
    @suites = @suites.page(params[:page])
  end

  def search
    @suites        = @suites.template.order(:name).search(params[:q]).result.page(params[:page])
    json           = {}
    json[:results] = @suites.collect { |s| { id: s.id, text: s.name } }
    json[:more]    = !@suites.last_page?

    render json: json.to_json
  end

  def new
    @suite.is_template = true
    render template: "suites/new"
  end


  private

  def instance_filter
    @suites = @suites.where(instance_id: current_instance_id) if @suites
  end
end
