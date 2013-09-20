class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    alias_action [ :index, :search ], to: :list
    alias_action :new_from_template,  to: :create
    alias_action :confirm_destroy,    to: :destroy

    alias_action [
      :show,
      :color_table,
      :search_participants
    ], to: :view

    alias_action [
      :select_users,
      :add_users,
      :remove_users,
      :add_generic_evaluations,
      :remove_generic_evaluations
    ], to: :contribute_to

    if user.has_role?(:admin)
      can :manage, :all
    elsif user.has_role?(:superuser)
      can :manage, :all

      # Users
      cannot :manage, User

      # Suites
      cannot :manage,         Suite
      can :create,            Suite
      can [ :view, :contribute_to, :update ], Suite do |suite|
        suite.is_template? || user.has_role?(:suite_manager, suite)
      end
      can :destroy,           Suite do |suite|
        !suite.is_template && user.has_role?(:suite_manager, suite)
      end

      # Students
      cannot :destroy, Student
    end

    # Suites and associated models
    can :list,                     Suite
    can [ :view, :contribute_to ], Suite do |suite|
      user.has_role?(:suite_contributor, suite)
    end
    can :search, [ User, Student, Group, Evaluation ]
    can :view,   [ Student, Group ]

    can :list,   Instance
    can :select, Instance do |instance|
      user.has_role?(:member, instance)
    end

    # Updating the user's details
    can :update, User, id: user.id
  end
end
