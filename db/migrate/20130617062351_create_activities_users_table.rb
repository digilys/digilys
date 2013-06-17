class CreateActivitiesUsersTable < ActiveRecord::Migration
  def up
    create_table :activities_users, id: false do |t|
      t.references :activity
      t.references :user
    end

    add_index :activities_users, [ :activity_id, :user_id ]
  end

  def down
    drop_table :activities_users
  end
end
