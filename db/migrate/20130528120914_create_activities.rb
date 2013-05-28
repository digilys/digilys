class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.references :suite, :meeting

      t.string :type
      t.string :status
      t.string :name
      t.text   :description
      t.text   :notes

      t.timestamps
    end
  end
end
