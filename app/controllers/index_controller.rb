class IndexController < ApplicationController
  skip_authorization_check

  def index
    load_dashboard_data if user_signed_in?
  end


  private

  def load_dashboard_data
    @suites                 = Suite.regular.order(:updated_at).limit(10)

    evaluations             = Evaluation.with_type(:suite).where_suite_manager(current_user).order("date asc")
    overdue_evaluations     = evaluations.overdue
    upcoming_evaluations    = evaluations.upcoming.limit(5)

    @evaluations            = {}
    @evaluations[:overdue]  = overdue_evaluations unless overdue_evaluations.blank?
    @evaluations[:upcoming] = upcoming_evaluations unless upcoming_evaluations.blank?

    unless current_user.has_role?(:admin)
      @suites.with_role(:suite_manager, current_user)
    end
  end
end
