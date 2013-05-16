class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    if user.has_role?(:admin)
      can :manage, :all
    elsif user.has_role?(:superuser)
      can :manage, :all
    end
  end
end
