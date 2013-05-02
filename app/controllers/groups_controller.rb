class GroupsController < ApplicationController
  layout "admin"

  def index
    @groups = Group.includes(parent: :parent).order(:name).page(params[:page])
  end

  def show
    @group = Group.find(params[:id])
  end

  def search
    @groups = Group.with_parents(2).page(params[:page]).search(params[:q]).result

    render json: @groups.collect { |s|
      text = [ s.name, s.parent.try(:name), s.parent.try(:parent).try(:name) ].compact.join(", ")
      { id: s.id, text: text }
    }.to_json
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

  def select_students
    @group = Group.find(params[:id])
  end

  def add_students
    group = Group.find(params[:id])
    group.add_students(params[:group][:students])

    flash[:success] = t(:"groups.add_students.success")
    redirect_to group
  end

  def remove_students
    group = Group.find(params[:id])
    group.remove_students(params[:student_ids])

    flash[:success] = t(:"groups.remove_students.success")
    redirect_to group
  end
end
