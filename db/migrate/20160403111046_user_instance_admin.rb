class UserInstanceAdmin < ActiveRecord::Migration
  def up
    remove_column :instances, :user_id
    add_column :users, :admin_instance_id, :integer
  end
  def down
    add_column :instances, :user_id, :integer
    remove_column :users, :admin_instance_id, :integer
  end
end
