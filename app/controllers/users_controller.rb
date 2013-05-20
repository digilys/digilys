class UsersController < ApplicationController
  layout "admin"

  load_and_authorize_resource

  def search
    @users = @users.page(params[:page]).search(params[:q]).result
    render json: @users.collect { |u| { id: u.id, text: u.email } }.to_json
  end
end
