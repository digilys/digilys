class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    active_instance = user.active_instance
    is_instance_admin = user.is_admin_of?(active_instance)

    alias_action :index, :closed, :search, to: :list
    alias_action :new_from_template,       to: :create
    alias_action :confirm_destroy,         to: :destroy

    alias_action :submit_report,
                 :destroy_report,
                 :report_all,
                 :submit_report_all,
      to: :report

    alias_action :add_users,
                 :remove_users,
                 :select_users,
      to: :associate_users

    alias_action :show,
                 :select,
                 :search_participants,
                 :save_state,
                 :clear_state,
                 :add_student_data,
      to: :view

    alias_action :update,
                 :report,
                 :associate_users,
      to: :change

    alias_action :destroy,
                 :add_contributors,
                 :remove_contributors,
                 :confirm_status_change,
                 :change_status,
      to: :control

    if user.has_role?(:admin)
      can :manage, :all
      can :restore, :all
      can :change_instance, User
      can :manage, Role
    elsif user.has_role?(:planner)
      # Students
      can    :manage, Student
      cannot :destroy, Student

      can :manage, Role

      # Groups
      can :manage, Group

      # Suites
      can :create,            Suite
      can [ :view, :change, :restore ], Suite do |suite|
        suite.is_template
      end
      can :list_closed_suites, Suite
      cannot [:restore], Suite

      # Evaluations
      can :manage,                         Evaluation
      cannot [ :view, :change, :destroy ], Evaluation do |evaluation|
        evaluation.type_suite?
      end
      cannot [:restore], Evaluation

      # Color tables
      can :create, ColorTable
    elsif is_instance_admin

      can :create, User
      can [ :manage, :view, :edit, :change ], User do |u|
        u.instances.include?(active_instance) && !u.is_administrator?
      end
      can [ :destroy ], User do |u|
        u.instances.include?(active_instance) && !u.is_administrator?
      end
      cannot :change_instance, User

      can :manage, Role

      can [:manage, :create, :destroy, :restore], Suite do |suite|
        # No suite instance yet if create
        !suite.is_template? && (!suite.instance || user.is_admin_of?(suite.instance))
      end
      can [:view], Suite do |suite|
        user.is_admin_of?(suite.instance)
      end
      can [:manage, :restore], Evaluation
      cannot [:edit, :update, :destroy, :create], Evaluation do |evaluation|
        evaluation.type == 'template'
      end

      can :control, Instance
      # Groups
      can [ :manage ], Group
      cannot [ :edit, :update, :destroy, :create_new ], Group
      cannot [ :select_students, :add_students, :remove_students ], Group
      cannot [ :select_users, :add_users, :remove_users ], Group
      can [:manage], Student
      cannot [:edit, :update, :destroy, :create], Student
    end

    can [ :view, :associate_users ], Instance do |inst|
      user.is_admin_of?(inst)
    end

    can :list,    Suite
    can :view,    Suite do |suite|
      user.has_role?(  :suite_manager,     suite) ||
        user.has_role?(:suite_member,      suite) ||
        user.has_role?(:suite_contributor, suite)
    end
    can :change,  Suite do |suite|
      user.has_role?(  :suite_manager,     suite) ||
        user.has_role?(:suite_contributor, suite)
    end
    can :control, Suite do |suite|
      user.has_role?(:suite_manager, suite)
    end

    readonly_associations = [
      Participant,
      Evaluation,
      Meeting,
      Activity
    ]

    can :view, readonly_associations do |e|
      e.suite && can?(:view, e.suite)
    end
    can [ :view, :create, :change, :destroy ], readonly_associations do |e|
      e.suite && can?(:change, e.suite)
    end
    can :report, Evaluation do |e|
      e.suite && can?(:view, e.suite)
    end
    can :report, Activity do |activity|
      activity.users.include?(user)
    end

    can :search, [ User, Student, Group, Evaluation ]
    can :view,   [ Student, Group ]

    can :list, ColorTable
    can :view, ColorTable do |c|
      c.suite && can?(:view, c.suite) ||
        user.has_role?(:reader, c) ||
        user.has_role?(:editor, c) ||
        user.has_role?(:manager, c)
    end
    can :change, ColorTable do |c|
      c.suite && can?(:change, c.suite) ||
        user.has_role?(:editor, c) ||
        user.has_role?(:manager, c)
    end

    can :view, TableState do |s|
      can?(:view, s.base)
    end
    can :manage, TableState do |s|
      can?(:change, s.base)
    end

    can :list,   Instance
    can :select, Instance do |instance|
      user.has_role?(:member, instance) || user.is_admin_of?(instance)
    end


    # explicit denies
    if user.has_role?(:member)
      cannot :list_closed_suites, Suite
    end
    unless user.has_role?(:admin) || user.has_role?(:planner) || user.is_instance_admin?
      cannot [:create, :destroy], Suite
    end

    # Updating the user's details
    can :update, User, id: user.id
  end
end
