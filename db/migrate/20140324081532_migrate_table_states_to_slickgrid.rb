class MigrateTableStatesToSlickgrid < ActiveRecord::Migration
  def up
    TableState.find_each do |table_state|
      slickgrid_state = {}

      if table_state.data["ColReorder"]
        slickgrid_state["columnOrder"] = table_state.data["ColReorder"].collect do |id|
          process_datatables_column_id(id)
        end
      end
      if table_state.data["abVisCols"]
        slickgrid_state["hiddenColumns"] = table_state.data["abVisCols"].collect do |id|
          process_datatables_column_id(id)
        end
      end

      table_state.data = slickgrid_state
      table_state.save!
    end
  end

  def down
    TableState.find_each do |table_state|
      datatable_state = {}

      if table_state.data["columnOrder"]
        datatable_state["ColReorder"] = table_state.data["columnOrder"].collect do |id|
          process_slickgrid_column_id(id)
        end
      end
      if table_state.data["hiddenColumns"]
        datatable_state["abVisCols"] = table_state.data["hiddenColumns"].collect do |id|
          process_slickgrid_column_id(id)
        end
      end

      table_state.data = datatable_state
      table_state.save!
    end
  end

  private

  def process_datatables_column_id(id)
    case id
    when "datatable-column-student-names"
      return "student-name"
    when /^datatable-column-/
      return id.sub(/^datatable-column-/, "")
    else
      return nil
    end
  end

  def process_slickgrid_column_id(id)
    case id
    when "student-name"
      return "datatable-column-student-names"
    else
      return "datatable-column-#{id}"
    end
  end
end
