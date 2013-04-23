class IndexController < ApplicationController
  def index
  end

  layout "admin", only: :admin
  def admin
  end
end
