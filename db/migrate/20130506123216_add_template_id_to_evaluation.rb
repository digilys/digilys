class AddTemplateIdToEvaluation < ActiveRecord::Migration
  def change
    add_column :evaluations, :template_id, :integer
  end
end
