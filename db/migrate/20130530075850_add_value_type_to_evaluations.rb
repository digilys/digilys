class AddValueTypeToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :value_type, :string, default: "numeric"
  end
end
