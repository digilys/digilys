class AddValueAliasesToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :value_aliases, :text
  end
end
