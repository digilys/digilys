class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.text :data

      t.references :customizer,   polymorphic: true
      t.references :customizable, polymorphic: true

      t.timestamps
    end
  end
end
