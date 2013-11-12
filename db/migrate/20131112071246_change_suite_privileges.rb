class ChangeSuitePrivileges < ActiveRecord::Migration
  def up
    roles = Suite.find_roles(:suite_contributor)

    roles.each do |role|
      role.users.each do |user|
        user.add_role :suite_member, role.resource
      end
    end
  end

  def down
    roles = Suite.find_roles(:suite_member)

    roles.each do |role|
      role.users.each do |user|
        user.add_role    :suite_contributor, role.resource
        user.remove_role :suite_member,      role.resource
      end
    end
  end
end
