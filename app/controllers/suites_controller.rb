class SuitesController < ApplicationController

  before_filter :process_incoming_participant_data, only: :create
  before_filter :load_from_template,                only: :new_from_template

  load_and_authorize_resource

  def index
    if !current_user.has_role?(:admin)
      @suites = @suites.with_role([:suite_manager, :suite_contributor], current_user)
    end

    @suites = @suites.regular.order(:name).page(params[:page])
  end

  def search_participants
    students = @suite.students.order(:last_name, :first_name).search(params[:sq]).result.page(params[:page])
    groups   = @suite.groups.order(:name).search(params[:gq]).result.page(params[:page])

    result  = students.collect { |s| { id: "s-#{s.id}", text: s.name } }
    result += groups.collect   { |g| { id: "g-#{g.id}", text: g.name } }

    json           = {}
    json[:results] = result
    json[:more]    = !students.last_page? || !groups.last_page?


    render json: json.to_json
  end

  def show
  end

  layout "fullpage", only: :color_table
  def color_table
    evaluations = Evaluation.with_type(:generic).order("name asc").partition { |e| @suite.generic_evaluations.include?(e.id) }
    @generic_evaluations = {
      included: evaluations.first,
      missing:  evaluations.last
    }
  end

  def new
    @suite.participants.build
  end

  def new_from_template
    @suite.participants.build
    render action: "new"
  end

  def create
    if @suite.save
      current_user.add_role :suite_manager, @suite
      flash[:success] = t(:"suites.create.success.#{@suite.is_template? ? "template" : "regular"}")
      redirect_to @suite
    else
      @suite.participants.clear
      @suite.participants.build
      render action: "new"
    end
  end

  def edit
  end

  def update
    if @suite.update_attributes(params[:suite])
      flash[:success] = t(:"suites.update.success.#{@suite.is_template? ? "template" : "regular"}")
      redirect_to @suite
    else
      render action: "edit"
    end
  end

  def confirm_destroy
  end
  def destroy
    @suite.destroy
    flash[:success] = t(:"suites.destroy.success.#{@suite.is_template? ? "template" : "regular"}")
    if @suite.is_template?
      redirect_to template_suites_url()
    else
      redirect_to suites_url()
    end
  end


  def select_users
  end

  def add_users
    users = User.where(id: params[:suite][:user_id].split(",")).all

    users.each do |user|
      user.add_role :suite_contributor, @suite
    end

    flash[:success] = t(:"suites.add_users.success")
    redirect_to @suite
  end

  def remove_users
    users = User.where(id: params[:suite][:user_id].split(",")).all

    users.each do |user|
      user.remove_role :suite_contributor, @suite
    end

    flash[:success] = t(:"suites.remove_users.success")
    redirect_to @suite
  end

  def add_generic_evaluations
    evaluation = Evaluation.with_type(:generic).find(params[:suite][:generic_evaluations])
    @suite.generic_evaluations << evaluation.id
    @suite.save
    redirect_to color_table_suite_url(@suite)
  end
  def remove_generic_evaluations
    evaluation = Evaluation.with_type(:generic).find(params[:evaluation_id])
    @suite.generic_evaluations.delete(evaluation.id)
    @suite.save
    redirect_to color_table_suite_url(@suite)
  end
  def add_student_data
    @suite.student_data << params[:key]
    @suite.save
    redirect_to color_table_suite_url(@suite)
  end
  def remove_student_data
    @suite.student_data.delete(params[:key])
    @suite.save
    redirect_to color_table_suite_url(@suite)
  end

  private

  # Loads an entity from a template id.
  # Required as a before_filter so it works with cancan's auth
  def load_from_template
    params[:suite][:name] = "" # Force a name change

    template = Suite.find(params[:suite][:template_id])
    @suite   = Suite.new_from_template(template, params[:suite])
  end

  # Convert incoming participant autocomplete data
  # to distinct entities that are compatible with rails
  # accepts_attributes_for
  def process_incoming_participant_data
    if params[:suite][:is_template] == "true" || params[:suite][:is_template].to_i == 1
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
  end
end
