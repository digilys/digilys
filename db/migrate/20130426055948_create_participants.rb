class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.references :suite
      t.references :student

      t.timestamps
    end
  end
end
