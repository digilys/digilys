class SuitesController < ApplicationController
  layout "admin"

  def index
    @suites = Suite.regular.order(:name).page(params[:page])
  end

  def template
    @suites = Suite.template.order(:name).page(params[:page])
  end

  def search
    @suites = Suite.template.page(params[:page]).search(params[:q]).result
    render json: @suites.collect { |s| { id: s.id, text: s.name } }.to_json
  end

  def show
    @suite = Suite.find(params[:id])
  end

  def new
    @suite = Suite.new
    @suite.participants.build
  end

  def new_from_template
    template = Suite.find(params[:suite][:template_id])
    @suite   = Suite.new_from_template(template, params[:suite])
    @suite.participants.build

    render action: "new"
  end

  def create
    if params[:suite][:is_template].to_i == 1
      # No participants allowed for templates
      params[:suite].delete(:participants_attributes)
    else
      # Convert comma separated student and group ids to distinct participant data
      process_participant_autocomplete_params(
        params[:suite][:participants_attributes].delete("0")
      ).each_with_index do |participant_data, i|
        params[:suite][:participants_attributes][i.to_s] = participant_data
      end
    end

    @suite = Suite.new(params[:suite])

    if @suite.save
      flash[:success] = t(:"suites.create.success")
      redirect_to @suite
    else
      @suite.participants.clear
      @suite.participants.build
      render action: "new"
    end
  end

  def edit
    @suite = Suite.find(params[:id])
  end

  def update
    @suite = Suite.find(params[:id])

    if @suite.update_attributes(params[:suite])
      flash[:success] = t(:"suites.update.success")
      redirect_to @suite
    else
      render action: "edit"
    end
  end

  def confirm_destroy
    @suite = Suite.find(params[:id])
  end
  def destroy
    suite = Suite.find(params[:id])
    suite.destroy

    flash[:success] = t(:"suites.destroy.success")
    redirect_to suites_url()
  end
end
