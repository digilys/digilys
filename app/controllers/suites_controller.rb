class SuitesController < ApplicationController
  def show
    @suite = Suite.find(params[:id])
  end
end