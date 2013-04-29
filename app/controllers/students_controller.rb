class StudentsController < ApplicationController
  layout "admin"

  def index
    @students = Student.order(:name).page(params[:page])
  end

  def search
    @students = Student.page(params[:page]).search(params[:q]).result
    render json: @students.collect { |s| { id: s.id, text: s.name } }.to_json
  end

  def show
    @student = Student.find(params[:id])
  end

  def new
    @student = Student.new
  end

  def create
    @student = Student.new(params[:student])

    if @student.save
      flash[:success] = t(:"students.create.success")
      redirect_to @student
    else
      render action: "new"
    end
  end

  def edit
    @student = Student.find(params[:id])
  end

  def update
    @student = Student.find(params[:id])

    if @student.update_attributes(params[:student])
      flash[:success] = t(:"students.update.success")
      redirect_to @student
    else
      render action: "edit"
    end
  end
end
