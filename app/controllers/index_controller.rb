class IndexController < ApplicationController
  skip_authorization_check

  def index
    load_dashboard_data if user_signed_in?
  end


  private

  def load_dashboard_data
    @suites                 = Suite.regular.with_role([:suite_manager, :suite_contributor], current_user).order(:updated_at).limit(10)

    evaluations             = Evaluation.with_type(:suite).where_suite_contributor(current_user).order("date asc")
    overdue_evaluations     = evaluations.overdue
    upcoming_evaluations    = evaluations.upcoming.limit(5)

    @evaluations            = {}
    @evaluations[:overdue]  = overdue_evaluations unless overdue_evaluations.blank?
    @evaluations[:upcoming] = upcoming_evaluations unless upcoming_evaluations.blank?

    @meetings               = Meeting.where_suite_contributor(current_user).upcoming.order("date asc").limit(10)

    @activities             = Activity.where_suite_contributor(current_user).with_status(:open).order("start_date asc nulls last, end_date asc nulls last, name asc").all

    unless current_user.has_role?(:admin)
      @suites.with_role(:suite_manager, current_user)
    end
  end
end
