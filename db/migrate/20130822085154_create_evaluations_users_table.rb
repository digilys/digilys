class CreateEvaluationsUsersTable < ActiveRecord::Migration
  def up
    create_table :evaluations_users, id: false do |t|
      t.references :evaluation
      t.references :user
    end

    add_index :evaluations_users, [ :evaluation_id, :user_id ], name: "index_evaluations_users_on_ids"
  end

  def down
    drop_table :evaluations_users
  end
end
