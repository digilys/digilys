class AddDetailsToStudents < ActiveRecord::Migration
  def up
    add_column :students, :personal_id, :string
    add_column :students, :first_name,  :string
    add_column :students, :last_name,   :string
    add_column :students, :gender,      :string
    add_column :students, :data,        :text

    Student.reset_column_information
    Student.find_each do |student|
      first, *last        = student.read_attribute(:name).split(" ")
      student.first_name  = first
      student.last_name   = last.join(" ")
      student.gender      = :male
      student.personal_id = student.id.to_s
      student.save!
    end

    remove_column :students, :name
  end

  def down
    add_column :students, :name, :string

    Student.reset_column_information
    Student.find_each do |student|
      student.name = "#{student.first_name} #{student.last_name}"
      student.save
    end

    remove_column :students, :personal_id
    remove_column :students, :first_name
    remove_column :students, :last_name
    remove_column :students, :gender
    remove_column :students, :data
  end
end
