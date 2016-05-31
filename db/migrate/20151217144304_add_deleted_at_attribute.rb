class AddDeletedAtAttribute < ActiveRecord::Migration
  def up
    add_column :roles, :deleted_at, :timestamp
    add_column :meetings, :deleted_at, :timestamp
    add_column :activities, :deleted_at, :timestamp
    add_column :color_tables, :deleted_at, :timestamp
    add_column :participants, :deleted_at, :timestamp
    add_column :series, :deleted_at, :timestamp
    add_column :table_states, :deleted_at, :timestamp

    # add_column :evaluations, :deleted_at, :timestamp
    add_column :results, :deleted_at, :timestamp
    add_column :taggings, :deleted_at, :timestamp
  end

  def down
    remove_column :roles, :deleted_at
    remove_column :meetings, :deleted_at
    remove_column :activities, :deleted_at
    remove_column :color_tables, :deleted_at
    remove_column :participants, :deleted_at
    remove_column :series, :deleted_at
    remove_column :table_states, :deleted_at

    # remove_column :evaluations, :deleted_at
    remove_column :results, :deleted_at
    remove_column :taggings, :deleted_at
  end
end
