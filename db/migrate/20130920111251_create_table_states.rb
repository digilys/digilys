class CreateTableStates < ActiveRecord::Migration
  def change
    create_table :table_states do |t|
      t.string :name
      t.text   :data

      t.references :base, polymorphic: true

      t.timestamps
    end
  end
end
