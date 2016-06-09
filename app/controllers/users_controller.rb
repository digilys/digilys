class UsersController < ApplicationController
  layout "fullpage"

  load_and_authorize_resource

  before_filter :instance_filter, only: [ :search ]
  before_filter :authorized_users, only: [ :index ]

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

  def new
    @user = User.new
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
    instance_ids = filter_instance_ids(params[:user].delete(:instance_ids))
    admin_instance_id = params[:user].delete(:admin_instance_id)

    if @user.send(update_method, params[:user])

      if can?(:manage, User)
        assign_role(@user, role_ids)     if role_ids
        assign_instances(@user, instance_ids) if instance_ids
        remove_prev_suites(@user, instance_ids) if instance_ids
        update_instance_admin(@user, admin_instance_id)
      end

      sign_in @user, bypass: true if is_self_update

      flash[:success] = t(:"users.update.success")
      redirect_to edit_user_url(@user)
    else
      render action: "edit"
    end
  end

  def create
    instance_ids = filter_instance_ids(params[:user].delete(:instance_ids))
    role_ids = params[:user].delete(:role_ids)

    admin_instance_id = params[:user].delete(:admin_instance_id)

    @user = User.new(params[:user])
    @user.active_instance = current_user.active_instance

    if @user.save
      assign_role(@user, role_ids)     if role_ids
      add_instance_admin(@user, admin_instance_id)
      assign_instances(@user, instance_ids) if instance_ids
      redirect_to users_path, notice: "User succesfully created!"
    else
      render :new
    end
  end

  def add_instance_admin(user, instance_id)
    instance = Instance.find_by_id(instance_id)
    return if instance.nil?
    user.add_role(:instance_admin, instance)
  end

  def update_instance_admin(user, instance_id)
    instance = Instance.find_by_id(instance_id)
    if user.is_instance_admin?
      return if user.admin_instance == instance

      user.remove_role(:instance_admin, user.admin_instance)
      add_instance_admin(user, instance_id)
    else
      add_instance_admin(user, instance_id)
    end
  end

  def confirm_destroy
  end

  def destroy
    @user.roles.each do |r|
      r.destroy
    end
    @user.destroy
    flash[:success] = t(:"users.destroy.success")
    redirect_to users_url()
  end


  private

  def assign_role(user, role_ids)
    roles = user.roles.where(resource_type: nil)
    user.roles.delete(*roles)

    if !(role_id = role_ids.try(:first)).blank?
      user.add_role Role.find(role_id).name
    end
  end

  def remove_prev_suites(user, instance_ids)
    incoming_suites = Suite.where(instance_id: instance_ids).all
    previous_suites = Suite.with_role(:suite_member, user).all
    removed = previous_suites - incoming_suites
    removed.each do |suite|
      user.remove_role(:suite_member, suite) unless user.is_admin_of?(suite.instance)
    end
  end

  def assign_instances(user, instance_ids)
    incoming = Instance.where(id: instance_ids).all
    previous = Instance.with_role(:member, user).all

    added   = incoming - previous
    removed = previous - incoming

    added.each do |i|
      user.add_role(:member, i)
    end
    removed.each do |i|
      user.remove_role(:member, i) unless user.is_admin_of?(i)
    end

    if user.active_instance.nil? || removed.include?(user.active_instance)
      user.active_instance = Instance.with_role(:member, user).first
      user.save
    end
  end

  def authorized_users
    @users = User if @users.nil?

    if current_user.has_role?(:admin)
      if current_instance.id == 1
        @users = @users
      else
        @users = @users.where("users.id IN (?) OR users.active_instance_id IS NULL", User.with_role(:member, current_instance))
      end
    else
      @users = @users.where("users.id IN (?)", User.with_role(:member, current_instance))
    end
    @users = @users.where("users.id NOT IN (?)", User.with_any_role(:admin)) unless current_user.is_administrator?
    @users = @users.where("users.id NOT IN (?)", User.with_any_role(:planner)) unless (current_user.is_administrator? || current_user.is_admin_of?(current_instance))
  end

  def instance_filter
    @users = User if @users.nil?
    @users = @users.with_role(:member, current_instance)
  end

  def filter_instance_ids(instance_ids)
    instance_ids = [] if instance_ids.nil?
    if !current_user.has_role?(:admin)
      instance_ids = instance_ids & [current_user.active_instance.id.to_s]
    end
    return instance_ids
  end
end
