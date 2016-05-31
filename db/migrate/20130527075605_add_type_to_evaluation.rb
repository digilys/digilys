class AddTypeToEvaluation < ActiveRecord::Migration
  def up
    add_column :evaluations, :deleted_at, :timestamp

    add_column :evaluations, :type, :string, default: "template"

    Evaluation.reset_column_information
    Evaluation.inheritance_column = :disable_inheritance

    Evaluation.find_each do |evaluation|
      if evaluation.suite_id.blank?
        evaluation.type = :template
      else
        evaluation.type = :suite
      end

      evaluation.save
    end
  end
  def down
    remove_column :evaluations, :type
    remove_column :evaluations, :deleted_at

  end
end
