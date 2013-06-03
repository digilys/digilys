class IndexController < ApplicationController
  skip_authorization_check

  def index
    load_dashboard_data if user_signed_in?
  end


  private

  def load_dashboard_data
    @suites = Suite.regular.order(:updated_at).limit(10)

    unless current_user.has_role?(:admin)
      @suites.with_role(:suite_manager, current_user)
    end
  end
end
