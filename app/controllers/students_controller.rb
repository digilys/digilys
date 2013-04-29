class StudentsController < ApplicationController
  layout "admin"

  def search
    @students = Student.page(params[:page]).search(params[:q]).result
    render json: @students.collect { |s| { id: s.id, text: s.name } }.to_json
  end
end
