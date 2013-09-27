class AddInvisibleToUsers < ActiveRecord::Migration
  def change
    add_column :users, :invisible, :boolean, default: false
  end
end
