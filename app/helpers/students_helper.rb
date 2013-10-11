module StudentsHelper
  def student_name(student)
    if current_user.name_ordering == :last_name
      "#{student.last_name}, #{student.first_name}"
    else
      "#{student.first_name} #{student.last_name}"
    end
  end
end
