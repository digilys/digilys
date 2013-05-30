class AddTargetToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :target, :string, default: "all"
  end
end
