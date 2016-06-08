class InstanceAdminRole < ActiveRecord::Migration
  def up
    User.all.each do |u|
      if !u.admin_instance.nil?
        u.add_role(:instance_admin, u.admin_instance)
      end
    end
    remove_column :users, :admin_instance_id
  end

  def down
    add_column :users, :admin_instance_id, :integer
    User.all.each do |u|
      Instance.all.each do |i|
        if u.has_role?(:instance_admin, i)
          u.remove_role(:admin, u.admin_instance)
          u.admin_instance = i
        end
      end
    end
  end
end
