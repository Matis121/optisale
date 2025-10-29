class HomeController < ApplicationController
  RECENT_ORDERS_LIMIT = 5

  def index
    user_orders = current_user.orders

    @orders_count = user_orders.count
    @products_count = current_user.products.count
    @invoices_count = current_user.invoices.count
    @recent_orders = user_orders.order(created_at: :desc).limit(RECENT_ORDERS_LIMIT)
    @today_orders_count = user_orders.created_today.count
  end
end
