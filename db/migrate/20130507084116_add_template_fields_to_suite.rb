class AddTemplateFieldsToSuite < ActiveRecord::Migration
  def change
    add_column :suites, :is_template, :boolean
    add_column :suites, :template_id, :integer
  end
end
