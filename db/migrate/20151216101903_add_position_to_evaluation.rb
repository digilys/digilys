class AddPositionToEvaluation < ActiveRecord::Migration
  def self.up
    add_column :evaluations, :position, :integer, default: 0
  end

  def self.down
    remove_column :evaluations, :position
  end
end
