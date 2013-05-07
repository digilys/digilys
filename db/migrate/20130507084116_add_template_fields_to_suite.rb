class AddTemplateFieldsToSuite < ActiveRecord::Migration
  def change
    add_column :suites, :is_template, :boolean, default: false
    add_column :suites, :template_id, :integer
  end
end
