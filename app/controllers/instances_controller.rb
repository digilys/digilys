class InstancesController < ApplicationController
  layout "fullpage"

  load_and_authorize_resource

  def index
    @instances = @instances.with_role(:member, current_user) unless can?(:manage, Instance)
    @instances = @instances.order(:name)

    if request.xhr?
      render partial: "list", layout: false if request.xhr?
    else
      @instances = @instances.page(params[:page])
    end
  end

  def select
    current_user.active_instance = @instance
    current_user.save!

    s = request.env["HTTP_REFERER"]
    # Switching instance may result in back no longer available. Resort to index.
    if s && s.include?('/groups/')
      redirect_to s.gsub(/\/groups\/.*/,'/groups')
    elsif s && s.include?('/students/')
      redirect_to s.gsub(/\/students\/.*/,'/students')
    elsif s && s.include?('/suites/')
      redirect_to s.gsub(/\/suites\/.*/,'/suites')
    elsif s && s.include?('/evaluations/')
      redirect_to s.gsub(/\/evaluations\/.*/,'/suites')
    elsif s && s.include?('/color_tables/')
      redirect_to s.gsub(/\/color_tables\/.*/,'/color_tables')
    else
      redirect_to :back
    end
  end

  def show
  end

  def new
  end

  def create
    if @instance.save
      flash[:success] = t(:"instances.create.success")
      redirect_to @instance
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    if @instance.update_attributes(params[:instance])
      flash[:success] = t(:"instances.update.success")
      redirect_to @instance
    else
      render action: "edit"
    end
  end

  def select_users
  end

  def add_users
    return redirect_to @instance if params[:instance].nil? or params[:instance][:user_id].nil?

    users = User.where(id: params[:instance][:user_id].split(",")).all

    users.each do |user|
      Suite.in_instance(@instance).each do |suite|
        user.add_role :suite_member, suite unless suite.users.include? user
        suite.touch
      end
      @instance.users << user unless @instance.users.include? user
    end

    @instance.touch

    flash[:success] = t(:"instances.add_users.success")
    redirect_to @instance
  end

  def remove_users
    return redirect_to @instance if params[:instance].nil? or params[:instance][:user_id].nil?

    users = User.where(id: params[:instance][:user_id].split(",")).all

    users.each do |user|
      Suite.in_instance(@instance).each do |suite|
        user.remove_role :suite_member, suite
        suite.touch
      end
      @instance.users.delete(user)
    end

    @instance.touch

    flash[:success] = t(:"instances.remove_users.success")
    redirect_to @instance
  end

end
