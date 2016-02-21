class AddUserIdToInstance < ActiveRecord::Migration
  def self.up
    add_column :instances, :user_id, :integer
  end
  def self.down
    remove_column :instances, :user_id, :integer
  end
end
