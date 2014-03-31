class CreateSeries < ActiveRecord::Migration
  def change
    create_table :series do |t|
      t.references :suite
      t.string     :name

      t.timestamps
    end

    add_column :evaluations, :series_id,         :integer
    add_column :evaluations, :is_series_current, :boolean, default: false
  end
end
