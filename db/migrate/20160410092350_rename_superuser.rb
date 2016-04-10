class RenameSuperuser < ActiveRecord::Migration
  def up
    Role.all.each do |role|
      if role.name == "superuser"
        role.name = "planner"
        role.save!
      end
    end
  end

  def down
    Role.all.each do |role|
      if role.name == "planner"
        role.name = "superuser"
        role.save!
      end
    end
  end
end
