class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, join_table: :users_roles
  belongs_to :resource, polymorphic: true

  attr_accessible :name

  scopify

  def self.authorized_roles(current_user)
    retval = []
    if current_user.has_role?(:admin)
      retval = Role.where(name: %w(admin planner)).all
    elsif current_user.is_admin_of?(current_user.active_instance)
      retval = [Role.where(name: "planner").first]
    elsif current_user.has_role?(:planner)
      retval = [Role.where(name: "planner").first]
    else
      retval = [Role.where(name: "member").first]
    end
    return retval
  end

end
