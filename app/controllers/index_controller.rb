class IndexController < ApplicationController
  skip_authorization_check

  def index
    load_dashboard_data
  end


  private

  def load_dashboard_data
    @suites = Suite.
      regular.
      where(instance_id: current_instance_id).
      with_role([:suite_manager, :suite_contributor], current_user).
      order(:updated_at).
      limit(10)

    evaluations = Evaluation.
      with_type(:suite).
      in_instance(current_instance_id).
      where_suite_contributor(current_user).
      order("date asc")

    overdue_evaluations     = evaluations.overdue.without_explicit_users + current_user.evaluations.overdue.order(:updated_at)
    upcoming_evaluations    = evaluations.upcoming.limit(5)
    @evaluations            = {}
    @evaluations[:overdue]  = overdue_evaluations unless overdue_evaluations.blank?
    @evaluations[:upcoming] = upcoming_evaluations unless upcoming_evaluations.blank?

    @meetings = Meeting.
      in_instance(current_instance_id).
      where_suite_contributor(current_user).
      upcoming.
      order("date asc").
      limit(10)

    @activities = current_user.
      activities.
      in_instance(current_instance_id).
      with_status(:open).
      order("start_date asc nulls last, end_date asc nulls last, name asc").
      all

    unless current_user.has_role?(:admin)
      @suites.with_role(:suite_manager, current_user)
    end
  end
end
