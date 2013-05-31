class AddStaninesToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :stanines, :text
  end
end
