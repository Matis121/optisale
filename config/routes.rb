Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  # Users management
  resources :users, except: [ :show ], path: "manage_users", as: "manage_users"

  # Storage
  namespace :storage do
    root to: "products#index"
    resources :products do
      collection do
        post :update_current_catalog_in_session
        post :update_current_warehouse_in_session
        post :update_current_price_group_in_session
      end
      resources :stock_movements, only: [ :index ]
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
    resources :addresses, controller: "order/addresses"
    resources :customer_pickup_points, controller: "order/customer_pickup_points"
    resources :customers, controller: "order/customers"
    resources :products, controller: "order/products"
  end

  # Order statuses
  resources :order_statuses, controller: "order_statuses"
  resources :order_status_groups, controller: "order_status_groups"

  # Main integrations index and management
  get "integrations", to: "integrations#index"

  # Invoicing integrations under /integrations path
  resources :invoicing_integrations, path: "integrations", as: "integrations", controller: "integrations" do
    member do
      post :test
    end
  end

  # Future: Marketplace integrations
  # resources :marketplace_integrations do
  #   member do
  #     post :test
  #   end
  # end

  # Future: Shipping integrations
  # resources :shipping_integrations do
  #   member do
  #     post :test
  #   end
  # end

  # Invoices (for viewing and managing)
  resources :invoices do
    member do
      post :sync_status
      post :cancel_invoice
      delete :delete_from_external
      post :restore_products
      post :restore_customer_data
    end
    resources :invoice_items, only: [ :destroy ]
  end

  # Receipts
  resources :receipts do
    member do
      post :restore_products
    end
    resources :receipt_items, only: [ :destroy ]
  end
end
