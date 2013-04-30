class CreateMeetings < ActiveRecord::Migration
  def change
    create_table :meetings do |t|
      t.references :suite
      t.string     :name
      t.date       :date
      t.boolean    :completed, default: false
      t.text       :notes

      t.timestamps
    end
  end
end
