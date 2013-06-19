class GroupsController < ApplicationController
  load_and_authorize_resource

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
end
