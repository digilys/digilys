class CreateColorTables < ActiveRecord::Migration
  def change
    create_table :color_tables do |t|
      t.string     :name
      t.text       :student_data, default: "[]"

      t.references :instance, :suite
      t.timestamps
    end

    create_table :color_tables_evaluations, id: false do |t|
      t.references :color_table
      t.references :evaluation
    end

    add_index :color_tables_evaluations, [ :color_table_id, :evaluation_id ], name: "index_colortab_eval_on_ids"
  end
end
