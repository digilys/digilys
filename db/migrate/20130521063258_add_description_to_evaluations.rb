class AddDescriptionToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :description, :string, limit: 1024
  end
end
