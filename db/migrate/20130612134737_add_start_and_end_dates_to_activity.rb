class AddStartAndEndDatesToActivity < ActiveRecord::Migration
  def up
    add_column    :activities, :start_date, :date
    rename_column :activities, :date,       :end_date
  end
  def down
    remove_column :activities, :start_date
    rename_column :activities, :end_date,  :date
  end
end
