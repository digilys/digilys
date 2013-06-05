class AddStudentDataToSuite < ActiveRecord::Migration
  def change
    add_column :suites, :student_data, :string, limit: 1024
  end
end
