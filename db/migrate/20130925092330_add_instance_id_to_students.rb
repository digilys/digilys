class AddInstanceIdToStudents < ActiveRecord::Migration
  def up
    add_column :students, :instance_id, :integer

    Student.reset_column_information

    instance = Instance.order(:id).first
    Student.update_all(instance_id: instance.id)
  end

  def down
    remove_column :students, :instance_id
  end
end
