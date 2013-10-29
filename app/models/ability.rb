class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    alias_action :index, :search,     to: :list
    alias_action :new_from_template,  to: :create
    alias_action :confirm_destroy,    to: :destroy

    alias_action :show,
                 :color_table,
                 :search_participants,
      to: :view

    alias_action :update,
                 :select_users,
                 :add_users,
                 :remove_users,
                 :add_generic_evaluations,
                 :remove_generic_evaluations,
      to: :change

    if user.has_role?(:admin)
      can :manage, :all
    elsif user.has_role?(:superuser)
      can :manage, :all

      # Instances
      cannot :manage, Instance

      # Users
      cannot :manage, User

      # Suites
      cannot :manage,         Suite
      can [ :list, :create ], Suite
      can [ :view, :change ], Suite do |suite|
        suite.is_template? || user.has_role?(:suite_manager, suite)
      end
      can :destroy,           Suite do |suite|
        !suite.is_template && user.has_role?(:suite_manager, suite)
      end

      # Students
      cannot :destroy, Student

    else # Normal user
      # Suites and associated models
      can :list,              Suite
      can [ :view, :change ], Suite do |suite|
        user.has_role?(:suite_contributor, suite)
      end
      can :search, [ User, Student, Group, Evaluation ]
      can :view,   [ Student, Group ]
    end

    can :list,   Instance
    can :select, Instance do |instance|
      user.has_role?(:member, instance)
    end

    # Updating the user's details
    can :update, User, id: user.id
  end
end
