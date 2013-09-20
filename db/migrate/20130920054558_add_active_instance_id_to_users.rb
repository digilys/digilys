class AddActiveInstanceIdToUsers < ActiveRecord::Migration
  def up
    add_column :users, :active_instance_id, :integer

    User.reset_column_information

    instance = Instance.order(:id).first

    User.find_each do |user|
      user.active_instance = instance
      user.save

      user.add_role :member, instance
    end
  end

  def down
    remove_column :users, :active_instance_id
  end
end
