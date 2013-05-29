class CreateActivitiesGroupsTable < ActiveRecord::Migration
  def up
    create_table :activities_groups, id: false do |t|
      t.references :activity
      t.references :group
    end

    add_index :activities_groups, [ :activity_id, :group_id ]
  end

  def down
    drop_table :activities_groups
  end
end
