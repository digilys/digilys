class IndexController < ApplicationController
  skip_authorization_check only: :index
  authorize_resource class: false, except: :index

  def index
  end
end
