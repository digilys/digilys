class CreateEvaluationsParticipantsTable < ActiveRecord::Migration
  def up
    create_table :evaluations_participants, id: false do |t|
      t.references :evaluation
      t.references :participant
    end

    add_index :evaluations_participants, [ :evaluation_id, :participant_id ], name: "index_evaluations_participants_on_ids"
  end

  def down
    drop_table :evaluations_participants
  end
end
