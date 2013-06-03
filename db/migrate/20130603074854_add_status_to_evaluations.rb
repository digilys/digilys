class AddStatusToEvaluations < ActiveRecord::Migration
  def up
    add_column :evaluations, :status, :string, default: "empty"
    add_index  :evaluations, :status

    Evaluation.reset_column_information
    Evaluation.inheritance_column = :disable_inheritance

    Evaluation.find_each do |evaluation|
      evaluation.update_status!
    end
  end
  def down
    remove_column :evaluations, :status
  end
end
