class CreateGroupsStudentsTable < ActiveRecord::Migration
  def up
    create_table :groups_students, id: false do |t|
      t.references :group
      t.references :student
    end

    add_index :groups_students, [ :group_id, :student_id ]
  end

  def down
    drop_table :groups_students
  end
end
