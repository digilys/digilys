class IndexController < ApplicationController
  skip_authorization_check only: :index
  authorize_resource class: false

  def index
  end

  layout "admin", only: :admin

  def admin
  end
end
