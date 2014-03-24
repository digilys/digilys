class AuthorizationsController < ApplicationController
  before_filter :validate_roles
  before_filter :load_and_authorize_subject
  before_filter :load_user

  respond_to :json
  layout false

  def create
    params[:roles].each do |role|
      @user.add_role role, @subject
    end

    render content_type: "application/json"
  end

  def destroy
    params[:roles].each do |role|
      @user.remove_role role, @subject
    end
    render json: { id: @user.id, name: @user.name, email: @user.email }.to_json
  end


  private

  def validate_roles
    if params[:roles]
      roles = params[:roles].to_s.split(",")

      roles.reject! { |r| !%w(reader editor manager).include?(r) }
      params[:roles] = roles
    else
      params[:roles] = []
    end
  end

  def load_and_authorize_subject
    if params[:color_table_id]
      @subject = ColorTable.find(params[:color_table_id])
    end

    authorize! :change, @subject
  end

  def load_user
    @user = User.find(params[:user_id])
  end
end
