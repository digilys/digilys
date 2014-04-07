class ErrorController < ApplicationController
  layout false

  def log
    p = params.reject { |k,v| %w(controller action).include?(k) }
    logger.error("Frontend error: #{Time.zone.now} #{p.to_json}")
    render nothing: true
  end


  private

  def skip_authorization?
    true
  end
end
