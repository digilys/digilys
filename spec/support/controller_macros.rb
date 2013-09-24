module ControllerMacros

  ## Devise macros
  def login_user(user_factory = :user)
    let(:logged_in_user) { FactoryGirl.create(user_factory) }

    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in logged_in_user
    end
  end

end
