class StudentsController < ApplicationController
  load_and_authorize_resource

  before_filter :instance_filter

  def index
    @students = @students.order(current_name_order)
    @students = @students.search(params[:q]).result      if has_search_param?
    @students = @students.page(params[:page])
  end

  def search
    @students      = @students.order(current_name_order).search(params[:q]).result.page(params[:page])
    json           = {}
    json[:results] = @students.collect { |s| { id: s.id, text: s.name } }
    json[:more]    = !@students.last_page?

    render json: json.to_json
  end

  def show
    render partial: "details_table", locals: { student: @student } if request.xhr?
  end

  def new
    @student.populate_generic_results
  end

  def create
    @student.instance = current_instance

    if @student.save
      flash[:success] = t(:"students.create.success")
      redirect_to @student
    else
      @student.populate_generic_results
      render action: "new"
    end
  end

  def edit
    @student.populate_generic_results
  end

  def update
    params[:student].delete(:instance)
    params[:student].delete(:instance_id)

    if @student.update_attributes(params[:student])
      flash[:success] = t(:"students.update.success")
      redirect_to @student
    else
      @student.populate_generic_results
      render action: "edit"
    end
  end

  def confirm_destroy
  end
  def destroy
    @student.destroy

    flash[:success] = t(:"students.destroy.success")
    redirect_to students_url()
  end

  def select_groups
  end

  def add_groups
    @student.add_to_groups(params[:student][:groups])

    flash[:success] = t(:"students.add_groups.success")
    redirect_to @student
  end

  def remove_groups
    @student.remove_from_groups(params[:group_ids])

    flash[:success] = t(:"students.remove_groups.success")
    redirect_to @student
  end


  private

  def instance_filter
    if @students
      @students = @students.where(instance_id: current_instance_id)
    elsif @student && !@student.new_record?
      raise ActiveRecord::RecordNotFound unless @student.instance_id == current_instance_id
    end
  end
end
