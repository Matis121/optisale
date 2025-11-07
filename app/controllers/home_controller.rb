class HomeController < ApplicationController
  RECENT_ORDERS_LIMIT = 5

  def index
    account_orders = current_account.orders

    @orders_count = account_orders.count
    @products_count = current_account.products.count
    @invoices_count = current_account.invoices.count
    @recent_orders = account_orders.order(created_at: :desc).limit(RECENT_ORDERS_LIMIT)
    @today_orders_count = account_orders.created_today.count
  end
end
