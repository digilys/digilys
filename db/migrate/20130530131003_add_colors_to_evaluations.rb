class AddColorsToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :colors, :text
  end
end
