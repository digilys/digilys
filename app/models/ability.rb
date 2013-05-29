class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    alias_action [ :index, :search, :template ], to: :list
    alias_action :new_from_template,             to: :create
    alias_action :confirm_destroy,               to: :destroy

    alias_action [
      :select_users,
      :add_users,
      :remove_users,
      :add_generic_evaluations,
      :remove_generic_evaluations
    ], to: :update

    if user.has_role?(:admin)
      can :manage, :all
    elsif user.has_role?(:superuser)
      can :manage, :all

      # Users
      cannot :manage, User

      # Suites
      cannot :manage, Suite
      can [ :list, :create ], Suite
      can [
        :show,
        :update,
        :color_chart
      ], Suite do |suite|
        suite.is_template? || user.has_role?(:suite_manager, suite)
      end
      can :destroy, Suite do |suite|
        !suite.is_template && user.has_role?(:suite_manager, suite)
      end

      # Students
      cannot :destroy, Student
    end

    # Generic user functionality
    can :update, User, id: user.id
  end
end
