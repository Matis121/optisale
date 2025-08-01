Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root "orders#index"


  # Storage
  namespace :storage do
    root to: "products#index"
    resources :products do
      collection do
        post :update_current_catalog_in_session
        post :update_current_warehouse_in_session
        post :update_current_price_group_in_session
      end
    end
    resources :warehouses
    resources :catalogs
    resources :price_groups
  end

  # Orders
  resources :orders do
    collection do
      patch :bulk_update
    end
    member do
      get :edit_extra_fields
      patch :update_extra_fields
      get :edit_payment
      patch :update_payment
      get :search_products
    end
    resources :addresses
    resources :customer_pickup_points
    resources :customers
  end

  # Order statuses
  resources :order_statuses

  # Order products
  resources :order_products
end
