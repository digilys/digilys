class GroupsController < ApplicationController
  layout "admin"

  def index
    @groups = Group.order(:name).page(params[:page])
  end

  def show
    @group = Group.find(params[:id])
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(params[:group])

    if @group.save
      flash[:success] = t(:"groups.create.success")
      redirect_to @group
    else
      render action: "new"
    end
  end

  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find(params[:id])

    if @group.update_attributes(params[:group])
      flash[:success] = t(:"groups.update.success")
      redirect_to @group
    else
      render action: "edit"
    end
  end

  def confirm_destroy
    @group = Group.find(params[:id])
  end
  def destroy
    group = Group.find(params[:id])
    group.destroy

    flash[:success] = t(:"groups.destroy.success")
    redirect_to groups_url()
  end
end
