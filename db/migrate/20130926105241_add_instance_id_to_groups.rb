class AddInstanceIdToGroups < ActiveRecord::Migration
  def up
    add_column :groups, :instance_id, :integer

    Group.reset_column_information

    instance = Instance.order(:id).first
    Group.update_all(instance_id: instance.id)
  end

  def down
    remove_column :groups, :instance_id
  end
end
