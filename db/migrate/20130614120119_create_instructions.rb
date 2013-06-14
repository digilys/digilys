class CreateInstructions < ActiveRecord::Migration
  def change
    create_table :instructions do |t|
      t.string :title
      t.string :for_page
      t.text   :body

      t.timestamps
    end

    add_index :instructions, :for_page
  end
end
