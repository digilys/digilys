class MigrateColorTables < ActiveRecord::Migration
  def up
    Suite.regular.find_each do |suite|
      color_table              = suite.create_color_table!(name: suite.name)
      color_table.evaluations  = suite.evaluations + suite.generic_evaluations(true)
      color_table.student_data = suite.student_data

      color_table.save!

      suite.table_states.each do |table_state|
        table_state.base = color_table
        table_state.save!
      end
    end
  end

  def down
    Suite.regular.find_each do |suite|
      color_table = suite.color_table

      suite.generic_evaluations = color_table.generic_evaluations.collect(&:id)
      suite.student_data = color_table.student_data

      suite.save!

      color_table.table_states.each do |table_state|
        table_state.base = suite
        table_state.save!
      end

      color_table.table_states(true)

      color_table.destroy
    end
  end
end
