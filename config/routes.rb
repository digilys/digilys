Digilys::Application.routes.draw do
  # Landing pages
  get "index/index"
  get "index/admin"

  resources :users, only: [ :index, :edit, :update ] do
    collection do
      get :search
    end
  end

  resources :groups do
    collection do
      get :search
    end
    member do
      get    :confirm_destroy
      get    :select_students
      put    :add_students
      delete :remove_students
    end
  end

  resources :students do
    collection do
      get :search
    end
    member do
      get    :confirm_destroy
      get    :select_groups
      put    :add_groups
      delete :remove_groups
    end
  end

  resources :suites do
    collection do
      get  :template
      get  :search
      post :new_from_template
    end
    member do
      get    :confirm_destroy
      get    :select_users
      put    :add_users
      delete :remove_users
    end

    resources :evaluations,  only: :new
    resources :participants, only: :new
    resources :meetings,     only: :new
  end

  resources :participants, only: [ :create, :destroy ] do
    member do
      get :confirm_destroy
    end
  end

  resources :evaluations do
    collection do
      get  :search
      post :new_from_template
    end
    member do
      get :confirm_destroy
      get :report
      put :submit_report
    end
  end

  resources :meetings, except: [ :index, :new ] do
    member do
      get :confirm_destroy
    end
  end

  namespace :visualize do
    resources :suites, only: :show
  end

  devise_for :users, path: "authenticate"

  mount RailsAdmin::Engine => "/radmin", as: "rails_admin"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "index#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
