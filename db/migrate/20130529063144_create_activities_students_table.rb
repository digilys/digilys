class CreateActivitiesStudentsTable < ActiveRecord::Migration
  def up
    create_table :activities_students, id: false do |t|
      t.references :activity
      t.references :student
    end

    add_index :activities_students, [ :activity_id, :student_id ]
  end

  def down
    drop_table :activities_students
  end
end
