class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    alias_action :index, :closed, :search, to: :list
    alias_action :new_from_template,       to: :create
    alias_action :confirm_destroy,         to: :destroy

    alias_action :submit_report,
                 :destroy_report,
      to: :report

    alias_action :add_users,
                 :remove_users,
                 :select_users,
      to: :associate_users

    alias_action :add_generic_evaluations,
                 :remove_generic_evaluations,
      to: :associate_generic_evaluations

    alias_action :add_student_data,
                 :remove_student_data,
      to: :associate_student_data

    alias_action :save_color_table_state,
                 :clear_color_table_state,
      to: :associate_table_state

    alias_action :show,
                 :select,
                 :color_table,
                 :search_participants,
                 :associate_generic_evaluations,
                 :associate_student_data,
                 :associate_table_state,
      to: :view

    alias_action :update,
                 :report,
                 :associate_users,
      to: :change

    alias_action :destroy,
                 :add_contributors,
                 :remove_contributors,
      to: :control

    if user.has_role?(:admin)
      can :manage, :all
    elsif user.has_role?(:superuser)
      # Students
      can    :manage, Student
      cannot :destroy, Student

      # Groups
      can    :manage, Group

      # Suites
      can :create,            Suite
      can [ :view, :change ], Suite do |suite|
        suite.is_template
      end

      # Evaluations
      can :manage,                         Evaluation
      cannot [ :view, :change, :destroy ], Evaluation do |evaluation|
        evaluation.type_suite?
      end
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
      e.suite &&
        user.has_role?(:suite_manager,     e.suite) ||
        user.has_role?(:suite_member,      e.suite) ||
        user.has_role?(:suite_contributor, e.suite)
    end
    can [ :create, :change, :destroy ], readonly_associations do |e|
      e.suite &&
        user.has_role?(:suite_manager,     e.suite) ||
        user.has_role?(:suite_contributor, e.suite)
    end
    can [ :view, :create, :change, :destroy ], TableState do |s|
      s.base &&
        user.has_role?(:suite_manager,     s.base) ||
        user.has_role?(:suite_member,      s.base) ||
        user.has_role?(:suite_contributor, s.base)
    end
    can :report, Evaluation do |e|
      e.suite &&
        user.has_role?(:suite_manager,     e.suite) ||
        user.has_role?(:suite_member,      e.suite) ||
        user.has_role?(:suite_contributor, e.suite)
    end
    can :report, Activity do |activity|
      activity.users.include?(user)
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
