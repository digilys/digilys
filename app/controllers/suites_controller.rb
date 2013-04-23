class SuitesController < ApplicationController
  layout "admin", except: :show

  def show
    @suite = Suite.find(params[:id])
  end

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
end
