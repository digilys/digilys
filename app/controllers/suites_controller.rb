class SuitesController < ApplicationController
  layout "admin"

  def new
    @suite = Suite.new
  end

  def create
    @suite = Suite.new(params[:suite])

    if @suite.save
      flash[:success] = t(:"suites.create.success")
      redirect_to @suite
    else
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
