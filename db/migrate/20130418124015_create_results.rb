class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.references :evaluation
      t.references :student

      t.integer    :value

      t.timestamps
    end
  end
end
