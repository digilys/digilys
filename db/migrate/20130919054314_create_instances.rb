class CreateInstances < ActiveRecord::Migration
  def up
    create_table :instances do |t|
      t.string :name

      t.timestamps
    end

    Instance.reset_column_information
    Instance.create(name: "DigiLys")
  end

  def down
    drop_table :instances
  end
end
