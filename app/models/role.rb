class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, join_table: :users_roles
  belongs_to :resource, polymorphic: true

  attr_accessible :name

  scopify

  def self.authorized_roles(current_user)
    return Role.where(name: %w(admin superuser)).all if current_user.is_administrator?

    return Role.where(name: "superuser").all if current_user.is_admin_of?(current_user.active_instance)
    return []
  end
end
