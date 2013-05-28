class AddGenericEvaluationsToSuite < ActiveRecord::Migration
  def change
    add_column :suites, :generic_evaluations, :string, limit: 1024
  end
end
