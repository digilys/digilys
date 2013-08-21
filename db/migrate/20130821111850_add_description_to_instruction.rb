class AddDescriptionToInstruction < ActiveRecord::Migration
  def up
    add_column    :instructions, :description, :text
    rename_column :instructions, :body,        :film
  end
  def down
    remove_column :instructions, :description
    rename_column :instructions, :film,        :body
  end
end
