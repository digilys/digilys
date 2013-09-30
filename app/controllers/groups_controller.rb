class GroupsController < ApplicationController
  load_and_authorize_resource

  before_filter :instance_filter

  def index
    @groups = @groups.order(:name)

    if has_search_param?
      @groups = @groups.search(params[:q]).result
    else
      @groups = @groups.top_level
    end

    @groups = @groups.page(params[:page])
  end

  def show
  end

  def search
    @groups        = @groups.with_parents(2, true).search(params[:q]).result.page(params[:page])
    json           = {}
    json[:results] = @groups.collect { |s|
      text = [ s.name, s.parent.try(:name), s.parent.try(:parent).try(:name) ].compact.join(", ")
      { id: s.id, text: text }
    }
    json[:more]    = !@groups.last_page?

    render json: json.to_json
  end

  def new
  end

  def create
    @group.instance = current_instance

    if @group.save
      flash[:success] = t(:"groups.create.success")
      redirect_to @group
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    params[:group].delete(:instance)
    params[:group].delete(:instance_id)

    if @group.update_attributes(params[:group])
      flash[:success] = t(:"groups.update.success")
      redirect_to @group
    else
      render action: "edit"
    end
  end

  def confirm_destroy
  end
  def destroy
    @group.destroy

    flash[:success] = t(:"groups.destroy.success")
    redirect_to groups_url()
  end

  def select_students
  end

  def add_students
    @group.add_students(params[:group][:students])

    flash[:success] = t(:"groups.add_students.success")
    redirect_to @group
  end

  def move_students
    return unless request.put?

    if params[:group][:group].blank?
      flash[:warning] = t(:"groups.move_students.group_missing")
      redirect_to action: "move_students"
    else
      destination_group = Group.where(instance_id: current_instance_id).find(params[:group][:group])
      destination_group.add_students(params[:student_ids].join(","))

      @group.remove_students(params[:student_ids])

      flash[:success] = t(:"groups.move_students.success")
      redirect_to @group
    end
  end

  def remove_students
    @group.remove_students(params[:student_ids])

    flash[:success] = t(:"groups.remove_students.success")
    redirect_to @group
  end

  def select_users
  end

  def add_users
    @group.add_users(params[:group][:users])
    flash[:success] = t(:"groups.add_users.success")
    redirect_to @group
  end

  def remove_users
    @group.remove_users(params[:user_ids])
    flash[:success] = t(:"groups.remove_users.success")
    redirect_to @group
  end


  private

  def instance_filter
    if @groups
      @groups = @groups.where(instance_id: current_instance_id)
    elsif @group && !@group.new_record?
      raise ActiveRecord::RecordNotFound unless @group.instance_id == current_instance_id
    end
  end
end
