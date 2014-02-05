class AddImportedToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :imported, :boolean, default: false
  end
end
