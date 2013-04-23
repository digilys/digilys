class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  # This picks up any layout set in the inheriting controller
  def record_not_found
    render :template => "shared/404", :status => 404
  end
end
