class AddDateToActivity < ActiveRecord::Migration
  def change
    add_column :activities, :date, :date
  end
end
