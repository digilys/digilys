class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    alias_action [ :index, :search, :template ], to: :list
    alias_action [ :select_users, :add_user ],   to: :update
    alias_action :new_from_template,             to: :create
    alias_action :confirm_destroy,               to: :destroy

    if user.has_role?(:admin)
      can :manage, :all
    elsif user.has_role?(:superuser)
      can :manage, :all

      # Suites
      cannot :manage, Suite
      can [ :list, :create ], Suite
      can [ :show, :update ], Suite do |suite|
        suite.is_template? || user.has_role?(:suite_manager, suite)
      end
      can :destroy, Suite do |suite|
        !suite.is_template && user.has_role?(:suite_manager, suite)
      end

      # Students
      cannot :destroy, Student
    end
  end
end
