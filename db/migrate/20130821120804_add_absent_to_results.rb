class AddAbsentToResults < ActiveRecord::Migration
  def change
    add_column :results, :absent, :boolean, default: false
  end
end
