class AdminAbility
  include CanCan::Ability

  def initialize(user)
    if user && user.has_role?(:admin)
      can :access, :rails_admin
      can :manage, :all

      # Don't allow the roles to be editable from the app
      cannot :new,     Role
      cannot :edit,    Role
      cannot :destroy, Role
    end
  end
end
