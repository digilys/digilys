class CreateEvaluations < ActiveRecord::Migration
  def change
    create_table :evaluations do |t|
      t.references :suite

      t.string     :name
      t.integer    :max_result
      t.integer    :red_below
      t.integer    :green_above

      t.timestamps
    end
  end
end
