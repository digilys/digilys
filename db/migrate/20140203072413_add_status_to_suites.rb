class AddStatusToSuites < ActiveRecord::Migration
  def change
    add_column :suites, :status, :string, default: "open"
  end
end
