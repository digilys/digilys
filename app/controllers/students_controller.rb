class StudentsController < ApplicationController
  layout "admin"

  # Needs to execute before load_and_authorize_resource
  before_filter :remove_empty_results, only: [ :create, :update ]

  load_and_authorize_resource

  def index
    @students = @students.order(:first_name, :last_name).page(params[:page])
  end

  def search
    @students = @students.page(params[:page]).search(params[:q]).result
    render json: @students.collect { |s| { id: s.id, text: s.name } }.to_json
  end

  def show
  end

  def new
    @student.populate_generic_results
  end

  def create
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

  def remove_empty_results
    params[:student][:generic_results_attributes].reject! { |key, value| value.try(:[], :value).blank? }
  end
end
