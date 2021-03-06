Rads::Application.routes.draw do
  resources :record_filters

  resources :annotations, only: [:index, :destroy]

  resources :cart_records, only: [:create, :destroy]

  get "record_provenance/show"
  resources :audited_activities, only: [:index, :show]

  resources :project_users, except: [:new, :create, :edit]

  resources :projects, except: [:destroy] do
    resources :project_memberships
    resources :project_affiliated_records, except: [:edit, :update]
    get 'can_affiliate_to', to: 'projects#can_affiliate_to'
  end

  resources :core_users, except: [:new, :create, :edit]
  resources :cores, except: [:edit, :update, :destroy] do
    resources :core_memberships, except: [:edit, :update]
  end

  resources :records, only: [:index, :show, :new, :create, :destroy] do
    resources :annotations, only: [:new, :create]
  end

  resource :cart, only: [:show, :update, :destroy]
  resources :repository_users

  get "switch_user/switch_to", as: 'switch_to'
  get "switch_user/destroy", as: 'switch_back'

  # omniauth
  get '/auth/shibboleth', as: 'shibboleth_login'
  get '/auth/:provider/callback', to: 'sessions#create'

  get "sessions/new"
  get "sessions/create"
  get "sessions/destroy"
  get "sessions/check", as: 'check'
  root 'repository_users#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".


  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
