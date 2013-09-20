class InstancesController < ApplicationController
  layout "fullpage"

  load_and_authorize_resource

  def index
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

    redirect_to root_url()
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
end
