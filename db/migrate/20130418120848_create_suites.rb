class CreateSuites < ActiveRecord::Migration
  def change
    create_table :suites do |t|
      t.string :name

      t.timestamps
    end
  end
end
