class AddInstanceIdToEvaluations < ActiveRecord::Migration
  def up
    add_column :evaluations, :instance_id, :integer

    Evaluation.reset_column_information

    instance = Instance.order(:id).first
    Evaluation.with_type(:generic).update_all(instance_id: instance.id)
    Evaluation.with_type(:template).update_all(instance_id: instance.id)
  end

  def down
    remove_column :evaluations, :instance_id
  end
end
