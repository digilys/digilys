class AddStanineToEvaluation < ActiveRecord::Migration
  def change
    add_column :evaluations, :stanine1, :integer
    add_column :evaluations, :stanine2, :integer
    add_column :evaluations, :stanine3, :integer
    add_column :evaluations, :stanine4, :integer
    add_column :evaluations, :stanine5, :integer
    add_column :evaluations, :stanine6, :integer
    add_column :evaluations, :stanine7, :integer
    add_column :evaluations, :stanine8, :integer
  end
end
