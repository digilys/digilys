class CreateInstancesUsersTable < ActiveRecord::Migration
  def up
    create_table :instances_users, id: false do |t|
      t.references :instance
      t.references :user
    end

    add_index :instances_users, [ :instance_id, :user_id ], name: "index_instances_users_on_ids"
  end

  def down
    drop_table :instances_users
  end
end
