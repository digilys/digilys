class UsersController < ApplicationController
  layout "fullpage"

  load_and_authorize_resource

  def index
    @users = @users.visible.order(:name)
    @users = @users.search(params[:q]).result if has_search_param?
    @users = @users.page(params[:page])
  end

  def search
    @users         = @users.visible.order(:name).search(params[:q]).result.page(params[:page])
    json           = {}
    json[:results] = @users.collect { |u| { id: u.id, text: "#{u.name}, #{u.email}" } }
    json[:more]    = !@users.last_page?

    render json: json.to_json
  end

  def edit
  end

  def update
    is_self_update = current_user == @user

    if params[:user][:password].blank?
      params[:user].delete(:current_password)
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
      update_method = :update_attributes
    else
      update_method = is_self_update ? :update_with_password : :update_attributes
    end

    role_ids = params[:user].delete(:role_ids)


    if @user.send(update_method, params[:user])

      if !role_ids.nil? && can?(:manage, User)
        @user.roles.clear

        if !(role_id = role_ids.try(:first)).blank?
          @user.add_role Role.find(role_id).name
        end
      end

      sign_in @user, bypass: true if is_self_update

      flash[:success] = t(:"users.update.success")
      redirect_to edit_user_url(@user)
    else
      render action: "edit"
    end
  end

  def confirm_destroy
  end

  def destroy
    @user.destroy
    flash[:success] = t(:"users.destroy.success")
    redirect_to users_url()
  end
end
