class HomeController < ApplicationController
  def index
    account_orders = current_account.orders

    @orders_count = account_orders.count
    @products_count = current_account.products.count
    @invoices_count = current_account.invoices.count
    @today_orders_count = account_orders.created_today.count
    
    # Get orders from this month for chart
    start_of_month = Time.current.beginning_of_month
    end_of_month = Time.current.end_of_month
    
    @monthly_orders = account_orders
      .where(created_at: start_of_month..end_of_month)
      .group_by_day(:created_at, range: start_of_month..end_of_month)
      .count
  end
end
