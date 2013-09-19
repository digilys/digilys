class InstancesController < ApplicationController
  layout "fullpage"

  load_and_authorize_resource

  def index
    @instances = @instances.order(:name)
    @instances = @instances.page(params[:page])
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
