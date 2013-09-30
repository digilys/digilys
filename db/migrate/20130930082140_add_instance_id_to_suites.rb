class AddInstanceIdToSuites < ActiveRecord::Migration
  def up
    add_column :suites, :instance_id, :integer

    Suite.reset_column_information

    instance = Instance.order(:id).first
    Suite.update_all(instance_id: instance.id)
  end

  def down
    remove_column :suites, :instance_id
  end
end
