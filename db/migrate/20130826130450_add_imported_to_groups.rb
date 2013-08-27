class AddImportedToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :imported, :boolean, default: false
  end
end
