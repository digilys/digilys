class AddSortColumnToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :sort, :integer
  end
end
